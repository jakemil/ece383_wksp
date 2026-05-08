----------------------------------------------------------------------------------
-- Lt Col James Trimble, 16-Jan-2025
-- color_mapper (previously scope face) determines the pixel color value based on the row, column, triggers, and channel inputs 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ece383_pkg.ALL;

entity color_mapper is
    Port ( clk : in  STD_LOGIC;
           color : out color_t;
           position : in  coordinate_t;
           barry_x : in  unsigned(9 downto 0);
           barry_y : in  unsigned(9 downto 0);
           zapper_x : in  unsigned(9 downto 0);
           zapper_y : in  unsigned(9 downto 0);
           missile_x : in  unsigned(9 downto 0);
           missile_y : in  unsigned(9 downto 0);
           game_state : in  std_logic_vector(1 downto 0);
           trigger : in  trigger_t;
           ch1 : in  channel_t;
           ch2 : in  channel_t);
end color_mapper;

architecture color_mapper_arch of color_mapper is

    -- define the game states (start, in play, gameover)
    constant ST_START : std_logic_vector(1 downto 0) := "00";
    constant ST_PLAYING : std_logic_vector(1 downto 0) := "01";
    constant ST_GAMEOVER : std_logic_vector(1 downto 0) := "10";

    -- define the sprite dimensions (from the ROM files)
    constant BARRY_W : integer := 32;
    constant BARRY_H : integer := 41;
    constant ZAPPER_W : integer := 40;
    constant ZAPPER_H : integer := 95;
    constant MISSILE_W : integer := 60;  
    constant MISSILE_H : integer := 33;
    constant BG_W : integer := 640;  
    constant BG_H : integer := 300;
    constant JETPACK_W : integer := 246;  
    constant JETPACK_H : integer := 55;
    constant JOYRIDE_W : integer := 226;  
    constant JOYRIDE_H : integer := 55;
    constant START_W : integer := 195;  
    constant START_H : integer := 30;
    constant FLY_W : integer := 209;  
    constant FLY_H : integer := 30;
    constant GO_W : integer := 167;  
    constant GO_H : integer := 30;

    -- define position of the menu/title graphics (tried to center it)
    constant JETPACK_X : integer := 80;
    constant JETPACK_Y : integer := 25;
    constant JOYRIDE_X : integer := JETPACK_X + JETPACK_W + 10;
    constant JOYRIDE_Y : integer := 25;

    constant STATE_Y : integer := 130;
    constant START_X : integer := (640 - START_W)/2;
    constant FLY_X : integer := (640 - FLY_W)/2;
    constant GO_X : integer := (640 - GO_W)/2;

    constant BG_X : integer := 0;
    constant BG_Y : integer := 180;

    -- define position of the score counter
    constant CNT_X : integer := BG_X + 40; -- 40 px from left edge of bg
    constant CNT_Y : integer := BG_Y + 10; -- 10 px below top of bg
    constant DIGIT_W : integer := 19;  -- max digit width (based on ROM)
    constant DIGIT_H : integer := 30;
    constant DIGIT_PITCH : integer := DIGIT_W + 1; -- 20

    constant DIG3_X : integer := CNT_X + 0*DIGIT_PITCH;  -- thousands
    constant DIG2_X : integer := CNT_X + 1*DIGIT_PITCH;  -- hundreds
    constant DIG1_X : integer := CNT_X + 2*DIGIT_PITCH;  -- tens
    constant DIG0_X : integer := CNT_X + 3*DIGIT_PITCH;  -- ones (10 Hz based on game counter)

    -- ROM M dimensions
    constant M_W : integer := 14;
    constant M_H : integer := 20;
    constant M_X : integer := CNT_X + 4*DIGIT_PITCH + 4;  -- small gap before m
    constant M_Y : integer := CNT_Y + (DIGIT_H - M_H);     -- baseline-aligned

    -- ROM widths for each digit (variable widths)
    constant W_D0 : integer := 17;
    constant W_D1 : integer := 8;
    constant W_D2 : integer := 17;
    constant W_D3 : integer := 17;
    constant W_D4 : integer := 19;
    constant W_D5 : integer := 17;
    constant W_D6 : integer := 17;
    constant W_D7 : integer := 17;
    constant W_D8 : integer := 17;
    constant W_D9 : integer := 17;

    -- create a clock divider to get a 10hz clock to drive the score
    constant CLK_Hz : integer := 25000000;
    constant TICK_DIV_MAX : integer := CLK_HZ / 10 - 1;

    -- tick counter for clock divider
    signal tick_div : unsigned(23 downto 0) := (others => '0');
    signal tick_10hz : std_logic := '0';

    -- counter for each digit
    signal d0, d1, d2, d3 : unsigned(3 downto 0) := (others => '0');

    -- signals for combinational logic to draw sprites
    signal row_i, col_i : integer;
    signal barry_x_i, barry_y_i, zapper_x_i, zapper_y_i, missile_x_i, missile_y_i : integer;

    -- boolean logic to draw sprite if in the sprite target
    signal in_barry, in_zapper, in_missile : std_logic;
    signal in_jetpack, in_joyride : std_logic;
    signal in_start, in_fly, in_go : std_logic;
    signal in_bg : std_logic;
    signal show_counter, show_start, show_fly, show_go : std_logic;

    signal in_dig0, in_dig1, in_dig2, in_dig3, in_any_dig, in_m : std_logic;
    signal active_value : unsigned(3 downto 0);
    signal dig_row : unsigned(4 downto 0);
    signal dig_col : unsigned(4 downto 0);
    signal m_row : unsigned(4 downto 0);
    signal m_col : unsigned(3 downto 0);
    
    -- sprite specific locations to index
    signal barry_row : unsigned(5 downto 0);  
    signal barry_col : unsigned(4 downto 0);
    signal zapper_row : unsigned(6 downto 0);  
    signal zapper_col : unsigned(5 downto 0);
    signal missile_row : unsigned(5 downto 0);  
    signal missile_col : unsigned(5 downto 0);
    signal jetpack_row : unsigned(5 downto 0);  
    signal jetpack_col : unsigned(7 downto 0);
    signal joyride_row : unsigned(5 downto 0);  
    signal joyride_col : unsigned(7 downto 0);
    signal start_row : unsigned(4 downto 0);  
    signal start_col : unsigned(7 downto 0);
    signal fly_row : unsigned(4 downto 0);  
    signal fly_col : unsigned(7 downto 0);
    signal go_row : unsigned(4 downto 0);  
    signal go_col : unsigned(7 downto 0);
    signal bg_row : unsigned(8 downto 0);  
    signal bg_col : unsigned(9 downto 0);

    -- N+1 signals
    signal in_barry_d, in_zapper_d, in_missile_d : std_logic;
    signal in_jetpack_d, in_joyride_d : std_logic;
    signal in_start_d, in_fly_d, in_go_d : std_logic;
    signal in_bg_d : std_logic;
    signal in_any_dig_d, in_m_d : std_logic;
    signal active_value_d : unsigned(3 downto 0);

    -- pallete outputs
    signal barry_idx, zapper_idx, missile_idx, bg_idx : std_logic_vector(7 downto 0);
    signal jetpack_idx, joyride_idx : std_logic_vector(7 downto 0);
    signal start_idx, fly_idx, go_idx : std_logic_vector(7 downto 0);
    signal d0_idx, d1_idx, d2_idx, d3_idx, d4_idx, d5_idx, d6_idx, d7_idx, d8_idx, d9_idx : std_logic_vector(7 downto 0);
    signal dig_idx_sel : std_logic_vector(7 downto 0);
    signal m_idx : std_logic_vector(7 downto 0);

    signal barry_rgb, zapper_rgb, missile_rgb, bg_rgb : std_logic_vector(23 downto 0);
    signal jetpack_rgb, joyride_rgb : std_logic_vector(23 downto 0);
    signal start_rgb, fly_rgb, go_rgb : std_logic_vector(23 downto 0);
    signal dig_rgb, m_rgb : std_logic_vector(23 downto 0);
    signal start_en, fly_en, go_en, m_en : std_logic;

    -- digit ROM enables
    signal en_d0, en_d1, en_d2, en_d3, en_d4, en_d5, en_d6, en_d7, en_d8, en_d9 : std_logic;

begin

    -- initialize
    row_i <= to_integer(position.row);
    col_i <= to_integer(position.col);
    barry_x_i <= to_integer(barry_x);   
    barry_y_i <= to_integer(barry_y);
    zapper_x_i <= to_integer(zapper_x);  
    zapper_y_i  <= to_integer(zapper_y);
    missile_x_i <= to_integer(missile_x); 
    missile_y_i <= to_integer(missile_y);
    show_start <= '1' when game_state = ST_START else '0';
    show_fly <= '1' when game_state = ST_PLAYING else '0';
    show_go <= '1' when game_state = ST_GAMEOVER else '0';
    show_counter <= '1' when game_state = ST_PLAYING else '0';

    -- clock divider to 10hz
    process(clk)
    begin
        if rising_edge(clk) then
            if tick_div = TICK_DIV_MAX then
                tick_div <= (others => '0');
                tick_10hz <= '1';
            else
                tick_div <= tick_div + 1;
                tick_10hz <= '0';
            end if;
        end if;
    end process;

    -- score counter process
    process(clk)
    begin
        if rising_edge(clk) then
            if game_state = ST_PLAYING then
                if tick_10hz = '1' then
                    if d0 = 9 then
                        d0 <= (others => '0');
                        if d1 = 9 then
                            d1 <= (others => '0');
                            if d2 = 9 then
                                d2 <= (others => '0');
                                if d3 = 9 then
                                    d3 <= (others => '0'); -- reset if at 9999
                                else
                                    d3 <= d3 + 1;
                                end if;
                            else
                                d2 <= d2 + 1;
                            end if;
                        else
                            d1 <= d1 + 1;
                        end if;
                    else
                        d0 <= d0 + 1;
                    end if;
                end if;
            else
                d0 <= (others => '0');
                d1 <= (others => '0');
                d2 <= (others => '0');
                d3 <= (others => '0');
            end if;
        end if;
    end process;

    --sprite bounding box (template helped waterfall with Claude to avoid redundant coding for this section)
    in_barry <= '1' when (col_i >= barry_x_i   and col_i < barry_x_i   + BARRY_W   and
                            row_i >= barry_y_i   and row_i < barry_y_i   + BARRY_H)   else '0';
    in_zapper <= '1' when (col_i >= zapper_x_i  and col_i < zapper_x_i  + ZAPPER_W  and
                            row_i >= zapper_y_i  and row_i < zapper_y_i  + ZAPPER_H)  else '0';
    in_missile <= '1' when (col_i >= missile_x_i and col_i < missile_x_i + MISSILE_W and
                            row_i >= missile_y_i and row_i < missile_y_i + MISSILE_H) else '0';
    in_jetpack <= '1' when (col_i >= JETPACK_X and col_i < JETPACK_X + JETPACK_W and
                            row_i >= JETPACK_Y and row_i < JETPACK_Y + JETPACK_H) else '0';
    in_joyride <= '1' when (col_i >= JOYRIDE_X and col_i < JOYRIDE_X + JOYRIDE_W and
                            row_i >= JOYRIDE_Y and row_i < JOYRIDE_Y + JOYRIDE_H) else '0';
    in_start <= '1' when (col_i >= START_X and col_i < START_X + START_W and
                            row_i >= STATE_Y and row_i < STATE_Y + START_H) else '0';
    in_fly <= '1' when (col_i >= FLY_X   and col_i < FLY_X   + FLY_W and
                            row_i >= STATE_Y and row_i < STATE_Y + FLY_H)   else '0';
    in_go <= '1' when (col_i >= GO_X    and col_i < GO_X    + GO_W and
                            row_i >= STATE_Y and row_i < STATE_Y + GO_H)    else '0';
    in_dig3 <= '1' when (col_i >= DIG3_X and col_i < DIG3_X + DIGIT_W and
                         row_i >= CNT_Y  and row_i < CNT_Y  + DIGIT_H) else '0';
    in_dig2 <= '1' when (col_i >= DIG2_X and col_i < DIG2_X + DIGIT_W and
                         row_i >= CNT_Y  and row_i < CNT_Y  + DIGIT_H) else '0';
    in_dig1 <= '1' when (col_i >= DIG1_X and col_i < DIG1_X + DIGIT_W and
                         row_i >= CNT_Y  and row_i < CNT_Y  + DIGIT_H) else '0';
    in_dig0 <= '1' when (col_i >= DIG0_X and col_i < DIG0_X + DIGIT_W and
                         row_i >= CNT_Y  and row_i < CNT_Y  + DIGIT_H) else '0';
    in_any_dig <= in_dig0 or in_dig1 or in_dig2 or in_dig3;
    in_m <= '1' when (col_i >= M_X and col_i < M_X + M_W and
                            row_i >= M_Y and row_i < M_Y + M_H) else '0';
    in_bg <= '1' when (col_i >= BG_X and col_i < BG_X + BG_W and
                            row_i >= BG_Y and row_i < BG_Y + BG_H) else '0';

    -- compute the locate address in the sprite
    barry_row <= resize(position.row - barry_y, 6);
    barry_col <= resize(position.col - barry_x, 5);
    zapper_row <= resize(position.row - zapper_y, 7);
    zapper_col <= resize(position.col - zapper_x, 6);
    missile_row <= resize(position.row - missile_y, 6);
    missile_col <= resize(position.col - missile_x, 6);
    jetpack_row <= resize(position.row - JETPACK_Y, 6);
    jetpack_col <= resize(position.col - JETPACK_X, 8);
    joyride_row <= resize(position.row - JOYRIDE_Y, 6);
    joyride_col <= resize(position.col - JOYRIDE_X, 8);
    start_row <= resize(position.row - STATE_Y, 5);
    start_col <= resize(position.col - START_X, 8);
    fly_row <= resize(position.row - STATE_Y, 5);
    fly_col <= resize(position.col - FLY_X, 8);
    go_row <= resize(position.row - STATE_Y, 5);
    go_col <= resize(position.col - GO_X, 8);
    bg_row <= resize(position.row - BG_Y, 9);
    bg_col <= resize(position.col - BG_X, 10);

    -- pick the active digit's value and slot-local col moving from left to right to account for changing width
    process(in_dig0, in_dig1, in_dig2, in_dig3, position, d0, d1, d2, d3)
    begin
        if in_dig3 = '1' then
            dig_col <= resize(position.col - DIG3_X, 5);
            active_value <= d3;
        elsif in_dig2 = '1' then
            dig_col <= resize(position.col - DIG2_X, 5);
            active_value <= d2;
        elsif in_dig1 = '1' then
            dig_col <= resize(position.col - DIG1_X, 5);
            active_value <= d1;
        else
            dig_col <= resize(position.col - DIG0_X, 5);
            active_value <= d0;
        end if;
    end process;

    dig_row <= resize(position.row - CNT_Y, 5);
    m_row <= resize(position.row - M_Y, 5);
    m_col <= resize(position.col - M_X, 4);

    -- only enable the ROM matching the active score value, and only within the ROM actual width
    en_d0 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=0 and dig_col < W_D0) else '0';
    en_d1 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=1 and dig_col < W_D1) else '0';
    en_d2 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=2 and dig_col < W_D2) else '0';
    en_d3 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=3 and dig_col < W_D3) else '0';
    en_d4 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=4 and dig_col < W_D4) else '0';
    en_d5 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=5 and dig_col < W_D5) else '0';
    en_d6 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=6 and dig_col < W_D6) else '0';
    en_d7 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=7 and dig_col < W_D7) else '0';
    en_d8 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=8 and dig_col < W_D8) else '0';
    en_d9 <= '1' when (in_any_dig='1' and show_counter='1' and active_value=9 and dig_col < W_D9) else '0';

    -- account for one cycle ROM latency with future signal
    process(clk)
    begin
        if rising_edge(clk) then
            in_barry_d <= in_barry;
            in_zapper_d <= in_zapper;
            in_missile_d <= in_missile;
            in_jetpack_d <= in_jetpack;
            in_joyride_d <= in_joyride;
            in_start_d <= in_start and show_start;
            in_fly_d <= in_fly and show_fly;
            in_go_d <= in_go and show_go;
            in_bg_d <= in_bg;
            in_any_dig_d <= in_any_dig and show_counter;
            in_m_d <= in_m and show_counter;
            active_value_d <= active_value;
        end if;
    end process;

    --instantiate the sprite roms and index
    u_barry_rom : entity work.barry_idx_rom
        port map(
            clk=> clk, 
            en=> in_barry,
            row_addr=> barry_row,
            col_addr=> barry_col, 
            color_index=> barry_idx);
    u_zapper_rom : entity work.zapper_idx_rom
        port map(
            clk=>clk, 
            en=>in_zapper,
            row_addr=>zapper_row, 
            col_addr=>zapper_col, 
            color_index=>zapper_idx);
    u_missile_rom : entity work.missile_idx_rom
        port map(
            clk=>clk, 
            en=>in_missile,
            row_addr=>missile_row, 
            col_addr=>missile_col, 
            color_index=>missile_idx);

    u_jetpack_rom : entity work.jetpack_idx_rom
        port map(
            clk=>clk, 
            en=>in_jetpack,
            row_addr=>jetpack_row, 
            col_addr=>jetpack_col, 
            color_index=>jetpack_idx);
    u_joyride_rom  : entity work.joyride_idx_rom
        port map(
            clk=>clk, 
            en=>in_joyride,
            row_addr=>joyride_row, 
            col_addr=>joyride_col, 
            color_index=>joyride_idx);
    
    start_en <= (in_start and show_start);
    u_start_rom : entity work.start_idx_rom
        port map(
            clk=>clk, 
            en=>start_en,
            row_addr=>start_row, 
            col_addr=>start_col, 
            color_index=>start_idx);
            
    fly_en <= (in_fly and show_fly);
    u_fly_rom : entity work.fly_idx_rom
        port map(
            clk=>clk, 
            en=>fly_en,
            row_addr=>fly_row, 
            col_addr=>fly_col, 
            color_index=>fly_idx);
            
    go_en <= (in_go and show_go);
    u_go_rom : entity work.game_over_idx_rom
        port map(
            clk=>clk,
            en=>go_en,
            row_addr=>go_row, 
            col_addr=>go_col, 
            color_index=>go_idx);

    u_background_rom : entity work.background_idx_rom
        port map(
            clk=>clk, 
            en=>in_bg,
            row_addr=>bg_row, 
            col_addr=>bg_col, 
            color_index=>bg_idx);

    -- instantiate the counter ROMS for indexing
    u_d0_rom : entity work.digit_0_idx_rom
        port map(
            clk=>clk,
            en=>en_d0, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d0_idx);
            
    u_d1_rom : entity work.digit_1_idx_rom
        port map(
            clk=>clk, 
            en=>en_d1, 
            row_addr=>dig_row, 
            col_addr=>dig_col(2 downto 0),
            color_index=>d1_idx);
            
    u_d2_rom : entity work.digit_2_idx_rom
        port map(
            clk=>clk, 
            en=>en_d2, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d2_idx);
            
    u_d3_rom : entity work.digit_3_idx_rom
        port map(
            clk=>clk, 
            en=>en_d3, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d3_idx);
            
    u_d4_rom : entity work.digit_4_idx_rom
        port map(
            clk=>clk, 
            en=>en_d4, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d4_idx);
            
    u_d5_rom : entity work.digit_5_idx_rom
        port map(
            clk=>clk, 
            en=>en_d5, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d5_idx);
            
    u_d6_rom : entity work.digit_6_idx_rom
        port map(
            clk=>clk, 
            en=>en_d6, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d6_idx);
            
    u_d7_rom : entity work.digit_7_idx_rom
        port map(
            clk=>clk, 
            en=>en_d7, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d7_idx);
    u_d8_rom : entity work.digit_8_idx_rom
        port map(
            clk=>clk, 
            en=>en_d8, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d8_idx);
            
    u_d9_rom : entity work.digit_9_idx_rom
        port map(
            clk=>clk, 
            en=>en_d9, 
            row_addr=>dig_row, 
            col_addr=>dig_col,
            color_index=>d9_idx);
            
    m_en <= (in_m and show_counter);
    u_m_rom : entity work.digit_m_idx_rom
        port map(
            clk=>clk,
            en=>m_en,
            row_addr=>m_row, 
            col_addr=>m_col, 
            color_index=>m_idx);

    --like a mux select the digit output
    with active_value_d select
        dig_idx_sel <= d0_idx when "0000",
                       d1_idx when "0001",
                       d2_idx when "0010",
                       d3_idx when "0011",
                       d4_idx when "0100",
                       d5_idx when "0101",
                       d6_idx when "0110",
                       d7_idx when "0111",
                       d8_idx when "1000",
                       d9_idx when "1001",
                       x"00"  when others;

    --use the pallete to get the color corresponding to index from sprite
    u_barry_pal : entity work.idx_palette 
        port map(
            color_index=>barry_idx, 
            rgb=>barry_rgb);
    u_zapper_pal : entity work.idx_palette 
        port map(
            color_index=>zapper_idx, 
            rgb=>zapper_rgb);
    u_missile_pal : entity work.idx_palette 
        port map(
            color_index=>missile_idx, 
            rgb=>missile_rgb);
    u_jetpack_pal : entity work.idx_palette 
        port map(
            color_index=>jetpack_idx, 
            rgb=>jetpack_rgb);
    u_joyride_pal : entity work.idx_palette 
        port map(
            color_index=>joyride_idx, 
            rgb=>joyride_rgb);
    u_start_pal : entity work.idx_palette 
        port map(
            color_index=>start_idx, 
            rgb=>start_rgb);
    u_fly_pal : entity work.idx_palette 
        port map(
            color_index=>fly_idx, 
            rgb=>fly_rgb);
    u_go_pal : entity work.idx_palette 
        port map(
            color_index=>go_idx, 
            rgb=>go_rgb);
    u_dig_pal : entity work.idx_palette 
        port map(
            color_index=>dig_idx_sel, 
            rgb=>dig_rgb);
    u_m_pal : entity work.idx_palette 
        port map(
            color_index=>m_idx, 
            rgb=>m_rgb);
    u_bg_pal : entity work.idx_palette 
        port map(
            color_index=>bg_idx, 
            rgb=>bg_rgb);

    -- final color blur out the black for transparent image
    color <= jetpack_rgb when (in_jetpack_d = '1' and jetpack_idx /= x"00") else
             joyride_rgb when (in_joyride_d = '1' and joyride_idx /= x"00") else
             start_rgb when (in_start_d = '1' and start_idx /= x"00") else
             fly_rgb when (in_fly_d = '1' and fly_idx /= x"00") else
             go_rgb when (in_go_d = '1' and go_idx /= x"00") else
             dig_rgb when (in_any_dig_d = '1' and dig_idx_sel /= x"00") else
             m_rgb when (in_m_d = '1' and m_idx /= x"00") else
             barry_rgb when (in_barry_d = '1' and barry_idx /= x"00") else
             missile_rgb when (in_missile_d = '1' and missile_idx /= x"00") else
             zapper_rgb when (in_zapper_d = '1' and zapper_idx /= x"00") else
             bg_rgb when (in_bg_d = '1') else
             BLACK;

end color_mapper_arch;