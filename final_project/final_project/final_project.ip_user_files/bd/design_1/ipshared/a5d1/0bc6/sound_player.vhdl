----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/07/2026 12:10:16 PM
-- Design Name: 
-- Module Name: sound_player - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- used to plays one of five sound effects through the audio codec.
-- codes : 0 = jetpack, 1 = missile_warning, 2 = missile_launch, 3 = laser_death, 4 = rocket_death
-- start pulses high for one cycle to (re)start playback. busy stays high until the current effect finishes.
entity sound_player is
    port (
        clk : in std_logic;
        reset_n : in std_logic;
        sample_tick : in std_logic;              
        start : in std_logic;
        sound_id : in std_logic_vector(2 downto 0);
        busy : out std_logic;
        sample_out : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of sound_player is

    -- define the lengths of the audio for use later
    constant LEN_JETPACK : integer := 53376;
    constant LEN_MISSILE_WARNING : integer := 32064;
    constant LEN_MISSILE_LAUNCH : integer := 72672;
    constant LEN_LASER_DEATH : integer := 47328;
    constant LEN_ROCKET_DEATH : integer := 97632;
    -- choose 17 bits to address the highest length of ROM
    constant ADDR_BITS : integer := 17;
    -- define a state as idle or play to control sound
    type state_t is (S_IDLE, S_PLAY);
    signal state : state_t := S_IDLE;
    --create an id signal to select which sound to play
    signal id_q : unsigned(2 downto 0) := (others => '0');
    --create an address signal to index the ROM with
    signal addr : unsigned(ADDR_BITS-1 downto 0) := (others => '0');
    --create signals to hold the output of each of the ROM (16 bit as we setup in the initial convertion using audacity
    signal jp_out, mw_out, ml_out, ld_out, rd_out : std_logic_vector(15 downto 0);
    --create enable signals
    signal en_jp, en_mw, en_ml, en_ld, en_rd : std_logic;
    --the selected sample
    signal sel_sample : std_logic_vector(15 downto 0);
    signal cur_len : integer;

begin

    -- enable the desired ROM when in play state (through start signal from datapath) and the input id matches
    en_jp <= '1' when state = S_PLAY and id_q = "000" else '0';
    en_mw <= '1' when state = S_PLAY and id_q = "001" else '0';
    en_ml <= '1' when state = S_PLAY and id_q = "010" else '0';
    en_ld <= '1' when state = S_PLAY and id_q = "011" else '0';
    en_rd <= '1' when state = S_PLAY and id_q = "100" else '0';

    -- instantiate all of the sfx roms
    u_jp : entity work.sfx_jetpack_rom 
    port map (clk => clk, 
              en => en_jp,
              addr => addr(15 downto 0), 
              sample_out => jp_out);

    u_mw : entity work.sfx_missile_warning_rom
    port map (clk => clk, en => en_mw,
              addr => addr(14 downto 0), 
              sample_out => mw_out);

    u_ml : entity work.sfx_missile_launch_rom
    port map (clk => clk, 
              en => en_ml,
              addr => addr(16 downto 0), 
              sample_out => ml_out);

    u_ld : entity work.sfx_laser_death_rom
    port map (clk => clk, 
              en => en_ld,
              addr => addr(15 downto 0), 
              sample_out => ld_out);

    u_rd : entity work.sfx_rocket_death_rom
    port map (clk => clk, 
              en => en_rd,
              addr => addr(16 downto 0), 
              sample_out => rd_out);

    -- select the id for desired sfx in a MUX style
    with id_q select
        sel_sample <= jp_out when "000",
                      mw_out when "001",
                      ml_out when "010",
                      ld_out when "011",
                      rd_out when "100",
                      x"0000" when others;
    -- select the length for the desired sfx
    with id_q select
        cur_len <= LEN_JETPACK when "000",
                   LEN_MISSILE_WARNING when "001",
                   LEN_MISSILE_LAUNCH when "010",
                   LEN_LASER_DEATH when "011",
                   LEN_ROCKET_DEATH when "100",
                   1 when others;

    -- create process
    fsm : process(clk)
    begin
        if rising_edge(clk) then
            -- reset case
            if reset_n = '0' then
                state <= S_IDLE;
                addr <= (others => '0');
                id_q <= (others => '0');
            else
                case state is
                    -- if start is 1 then set id and put in play state
                    when S_IDLE =>
                        if start = '1' then
                            id_q <= unsigned(sound_id);
                            addr <= (others => '0');
                            state <= S_PLAY;
                        end if;
                    -- check for potentially new sound
                    when S_PLAY =>
                        if start = '1' then
                            -- Software re-triggered: restart (possibly different sound)
                            id_q <= unsigned(sound_id);
                            addr <= (others => '0');
                        -- if new sound is ready then iterate address if not only through the whole sfx in ROM
                        elsif sample_tick = '1' then
                            if to_integer(addr) >= cur_len - 1 then
                                state <= S_IDLE;
                                addr  <= (others => '0');
                            else
                                addr <= addr + 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    busy <= '1' when state = S_PLAY else '0';
    -- choose sample out
    sample_out <= sel_sample when state = S_PLAY else x"0000";

end architecture;