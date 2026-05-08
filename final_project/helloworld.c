/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

//this is code to drive the jetpack joyride game

#include <stdint.h>
#include "xparameters.h"

//set the base address
#define MY_LAB2_BASE        XPAR_MY_LAB2_0_S00_AXI_BASEADDR

#define REG_WRITE32(off, val) (*(volatile uint32_t *)((MY_LAB2_BASE) + (off)) = (val))
#define REG_READ32(off)       (*(volatile uint32_t *)((MY_LAB2_BASE) + (off)))

//set register addresses
#define REG_BARRY_X_OFF     (11 * 4)
#define REG_BARRY_Y_OFF     (12 * 4)
#define REG_ZAPPER_X_OFF    (13 * 4)
#define REG_ZAPPER_Y_OFF    (14 * 4)
#define REG_MISSILE_X_OFF   (15 * 4)
#define REG_MISSILE_Y_OFF   (16 * 4)
#define REG_NES_BUTTONS_OFF (17 * 4)
#define REG_GAME_STATE_OFF  (18 * 4)
#define REG_SFX_OFF         (21 * 4)

//these are the bit masks according to our shift register 8 bit output
#define NES_A       0x01
#define NES_B       0x02
#define NES_SELECT  0x04
#define NES_START   0x08
#define NES_UP      0x10
#define NES_DOWN    0x20
#define NES_LEFT    0x40
#define NES_RIGHT   0x80

//set the game state and sfx codes (learned to use the u when debugging)
#define ST_START        0u
#define ST_PLAYING      1u
#define ST_GAMEOVER     2u
#define SFX_JETPACK         0u
#define SFX_MISSILE_WARN    1u
#define SFX_MISSILE_LAUNCH  2u
#define SFX_LASER_DEATH     3u
#define SFX_ROCKET_DEATH    4u

//define the screen and sprite dimensions for easy access
#define SCREEN_W            640
#define BG_X                0
#define BG_Y                180
#define BG_W                640
#define BG_H                270
#define BARRY_W             32
#define BARRY_H             41
#define ZAPPER_W            40
#define ZAPPER_H            95
#define MISSILE_W           60
#define MISSILE_H           33
#define BARRY_Y_MIN         (BG_Y)
#define BARRY_Y_MAX         (BG_Y + BG_H - BARRY_H)
#define ZAPPER_Y_MIN        (BG_Y)
#define ZAPPER_Y_MAX        (BG_Y + BG_H - ZAPPER_H)
#define MISSILE_Y_MIN       (BG_Y)
#define MISSILE_Y_MAX       (BG_Y + BG_H - MISSILE_H)
#define SPRITE_ENTRY_X      (SCREEN_W)
#define ZAPPER_EXIT_X       (-ZAPPER_W)
#define MISSILE_EXIT_X      (-MISSILE_W)

//define when the missile warning sounds
#define MISSILE_WARN_X      ((SCREEN_W * 2) / 3)

//define the player physics, found these to be best through iteration
#define POS_SCALE           16
#define BARRY_X             100
#define BARRY_Y_START_PX    300
#define BARRY_Y_START_Q     (BARRY_Y_START_PX * POS_SCALE)
#define GRAVITY_Q           4
#define THRUST_Q            12
#define MAX_VY_Q            80
#define ZAPPER_VX           (-4)
#define MISSILE_VX          (-6)
#define MISSILE_HEAD_START  200

//speed/pace, this feels best
#define FRAME_DELAY         6000

//variables for game use
static uint32_t game_state;
static int barry_y_q;
static int barry_vy;
static int zapper_x;
static int zapper_y;
static int missile_x;
static int missile_y;
static int missile_warned;

//helper functions to quickly access registers (discovered this method when debugging)
static inline void set_barry_pos(uint32_t x, uint32_t y) {
    REG_WRITE32(REG_BARRY_X_OFF, x & 0x3FF);
    REG_WRITE32(REG_BARRY_Y_OFF, y & 0x3FF);
}

static inline void set_zapper_pos(uint32_t x, uint32_t y) {
    REG_WRITE32(REG_ZAPPER_X_OFF, x & 0x3FF);
    REG_WRITE32(REG_ZAPPER_Y_OFF, y & 0x3FF);
}

static inline void set_missile_pos(uint32_t x, uint32_t y) {
    REG_WRITE32(REG_MISSILE_X_OFF, x & 0x3FF);
    REG_WRITE32(REG_MISSILE_Y_OFF, y & 0x3FF);
}

static inline uint32_t read_nes(void) {
    return REG_READ32(REG_NES_BUTTONS_OFF) & 0xFF;
}

static inline void set_game_state(uint32_t s) {
	REG_WRITE32(REG_GAME_STATE_OFF, s & 0x3);
}

static inline void play_sfx(uint32_t id) {
    uint32_t v = ((id & 0x7u) << 1) | 0x1u;
    REG_WRITE32(REG_SFX_OFF, v);
    REG_WRITE32(REG_SFX_OFF, 0);
}

static inline int sfx_busy(void) {
    return REG_READ32(REG_SFX_OFF) & 0x1;
}

static inline void delay_ticks(volatile int n) {
    while (n--) { /* spin */ }
}

//generic collision detection function
static inline int aabb_overlap(int ax, int ay, int aw, int ah, int bx, int by, int bw, int bh) {
    return (ax < bx + bw) && (ax + aw > bx) &&
           (ay < by + bh) && (ay + ah > by);
}

//randomizer for obstacles (recommended approach by claude)
static uint32_t rng_state = 0xC0FFEE42u;

static uint32_t simple_rand(void) {
    uint32_t s = rng_state;
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    rng_state = s;
    return s;
}

static int rand_in_range(int lo, int hi) {
    uint32_t span = (uint32_t)(hi - lo + 1);
    return lo + (int)(simple_rand() % span);
}

//initialize the game with barry and obstacles in starting positions
static void reset_game(void) {
    barry_y_q = BARRY_Y_START_Q;
    barry_vy  = 0;

    zapper_x  = SPRITE_ENTRY_X;
    zapper_y  = rand_in_range(ZAPPER_Y_MIN, ZAPPER_Y_MAX);

    missile_x = SPRITE_ENTRY_X + MISSILE_HEAD_START;
    missile_y = rand_in_range(MISSILE_Y_MIN, MISSILE_Y_MAX);
    missile_warned = 0;

    //use pos scale for more precision of movement and clean update
    set_barry_pos  ((uint32_t)BARRY_X,(uint32_t)(barry_y_q / POS_SCALE));
    set_zapper_pos ((uint32_t)zapper_x,  (uint32_t)zapper_y);
    set_missile_pos((uint32_t)missile_x, (uint32_t)missile_y);
}

//main game loop
int main(void) {
    //start at the start state
    game_state = ST_START;
    set_game_state(game_state);
    reset_game();
    uint32_t prev_buttons = 0;
    while (1) {
        uint32_t buttons = read_nes();
        uint32_t pressed = buttons & ~prev_buttons;
        prev_buttons     = buttons;

        switch (game_state) {

        //once start is pressed, go into the playing state
        case ST_START:
            if (pressed & NES_START) {
                reset_game();
                game_state = ST_PLAYING;
                set_game_state(game_state);
            }
            break;

        //while playing, update Barry based on thrust
        case ST_PLAYING: {
        	int thrusting;

        	if (buttons & NES_A) {
        	    thrusting = 1;
        	}
        	else {
        	    thrusting = 0;
        	}

            //gravity physics for realistic thrust, recommended by Claude
            int ay = GRAVITY_Q;
            if (thrusting) ay -= THRUST_Q;
            barry_vy += ay;
            if (barry_vy >  MAX_VY_Q) barry_vy =  MAX_VY_Q;
            if (barry_vy < -MAX_VY_Q) barry_vy = -MAX_VY_Q;
            barry_y_q += barry_vy;

            //ensure Barry doesnt fly off the screen (pos scale for fractional)
            if (barry_y_q < BARRY_Y_MIN * POS_SCALE) {
                barry_y_q = BARRY_Y_MIN * POS_SCALE;
                barry_vy  = 0;
            } else if (barry_y_q > BARRY_Y_MAX * POS_SCALE) {
                barry_y_q = BARRY_Y_MAX * POS_SCALE;
                barry_vy  = 0;
            }
            int barry_y_px = barry_y_q / POS_SCALE;
            set_barry_pos((uint32_t)BARRY_X, (uint32_t)barry_y_px);

            //have the zapper scroll left
            zapper_x += ZAPPER_VX;
            if (zapper_x < ZAPPER_EXIT_X) {
                zapper_x = SPRITE_ENTRY_X;
                zapper_y = rand_in_range(ZAPPER_Y_MIN, ZAPPER_Y_MAX);
            }
            set_zapper_pos((uint32_t)zapper_x, (uint32_t)zapper_y);

            //spawn in the missile and play launch sfx
            missile_x += MISSILE_VX;
            if (missile_x < MISSILE_EXIT_X) {
                missile_x = SPRITE_ENTRY_X;
                missile_y = rand_in_range(MISSILE_Y_MIN, MISSILE_Y_MAX);
                missile_warned = 0;
                play_sfx(SFX_MISSILE_LAUNCH);
            }
            set_missile_pos((uint32_t)missile_x, (uint32_t)missile_y);

            //play warning if not already and not playing another sound
            if (!missile_warned && missile_x < MISSILE_WARN_X) {
                if (!sfx_busy()) {
                    play_sfx(SFX_MISSILE_WARN);
                }
                missile_warned = 1;
            }

            //play the jetpack sfx with in use
            if (thrusting && !sfx_busy()) {
                play_sfx(SFX_JETPACK);
            }

            //check for collision and update to gameover state if occur
            if (aabb_overlap(BARRY_X, barry_y_px, BARRY_W, BARRY_H, zapper_x, zapper_y, ZAPPER_W, ZAPPER_H)) {
                play_sfx(SFX_LASER_DEATH);
                game_state = ST_GAMEOVER;
                set_game_state(game_state);
            } else if (aabb_overlap(BARRY_X, barry_y_px, BARRY_W, BARRY_H, missile_x, missile_y, MISSILE_W, MISSILE_H)) {
                play_sfx(SFX_ROCKET_DEATH);
                game_state = ST_GAMEOVER;
                set_game_state(game_state);
            }
            break;
        }

        //game over state resets
        case ST_GAMEOVER:
            if (pressed & NES_START) {
                reset_game();
                game_state = ST_PLAYING;
                set_game_state(game_state);
            }
            break;
        }

        delay_ticks(FRAME_DELAY);
    }

    return 0;
}

