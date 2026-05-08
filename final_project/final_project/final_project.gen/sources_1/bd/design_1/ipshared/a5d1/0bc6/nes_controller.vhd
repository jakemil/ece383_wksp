----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/05/2026 11:23:23 AM
-- Design Name: 
-- Module Name: nes_controller - Behavioral
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

-- this will serve as the file that drives and reads from the NES controller
entity nes_controller is
    generic (
        CLK_FREQ_HZ : integer := 100000000;
        -- from the slides
        POLL_RATE_HZ : integer := 60;
        --from the slides half-cycle delays of 6 microseconds
        BIT_HALF_PERIOD_US : integer := 6      -- 6 μs => ~83 kHz controller clock
    );
    port (
        clk : in  std_logic;
        reset_n : in  std_logic;
        -- physical pins to controller which I defined in the constraints file
        nes_latch : out std_logic;
        nes_pulse : out std_logic;
        nes_data : in  std_logic;
        -- button states to output to microblaze
        buttons : out std_logic_vector(7 downto 0)
    );
end nes_controller;
architecture Behavioral of nes_controller is
    --define the cycling times
    constant HALF_BIT_CYCLES : integer := (CLK_FREQ_HZ / 1000000) * BIT_HALF_PERIOD_US;
    constant POLL_GAP_CYCLES : integer := CLK_FREQ_HZ / POLL_RATE_HZ;
    --create states for each of the NES controller timings
    type state_t is (S_IDLE, S_LATCH, S_BIT_LOW, S_BIT_HIGH, S_DONE);
    signal state : state_t := S_IDLE;
    signal counter : integer range 0 to POLL_GAP_CYCLES := 0;
    -- create a shift reg and index to store the button states as we go
    signal bit_index : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal buttons_q : std_logic_vector(7 downto 0) := (others => '0');
    -- create signals to synchronize with
    signal data_s1, data_s2 : std_logic := '1';
begin
    -- synchonize the incoming data
    process(clk)
    begin
        if rising_edge(clk) then
            data_s1 <= nes_data;
            data_s2 <= data_s1;
        end if;
    end process;
    -- set up the fsm
    process(clk)
    begin
        if rising_edge(clk) then
            -- create a reset state
            if reset_n = '0' then
                state <= S_IDLE;
                counter <= 0;
                bit_index <= 0;
                shift_reg <= (others => '0');
                buttons_q <= (others => '0');
                nes_latch <= '0';
                nes_pulse <= '0';
            else
                case state is
                    when S_IDLE =>
                        nes_latch <= '0';
                        nes_pulse <= '0';
                        -- if we wait long enough then open the latch and reset counter
                        if counter >= POLL_GAP_CYCLES - 1 then
                            counter <= 0;
                            bit_index <= 0;
                            state <= S_LATCH;
                        else
                            counter <= counter + 1;
                        end if;
                    when S_LATCH =>
                        -- Latch high for 12 μs (2 half-bit periods) based on slides
                        nes_latch <= '1';
                        nes_pulse <= '0';
                        -- count for the 12us and then set latch low
                        if counter >= 2 * HALF_BIT_CYCLES - 1 then
                            counter <= 0;
                            state <= S_BIT_LOW;
                        else
                            counter <= counter + 1;
                        end if;
                    when S_BIT_LOW =>
                        -- Pulse low for 6 μs; sample data near end of low phase
                        nes_latch <= '0';
                        nes_pulse <= '0';
                        -- count for 6us then pulse high (change state)
                        if counter >= HALF_BIT_CYCLES - 1 then
                            counter <= 0;
                            -- store button state and invert so active high
                            shift_reg(bit_index) <= not data_s2;
                            state <= S_BIT_HIGH;
                        else
                            counter <= counter + 1;
                        end if;
                    when S_BIT_HIGH =>
                        -- Pulse high for 6 μs to advance the shift register
                        nes_latch <= '0';
                        nes_pulse <= '1';
                        -- check if at end of 6us
                        if counter >= HALF_BIT_CYCLES - 1 then
                            counter <= 0;
                            -- check if through shift register
                            if bit_index = 7 then
                                state <= S_DONE;
                            else
                                bit_index <= bit_index + 1;
                                state <= S_BIT_LOW;
                            end if;
                        else
                            counter <= counter + 1;
                        end if;
                    when S_DONE =>
                        -- reset and store output
                        nes_latch <= '0';
                        nes_pulse <= '0';
                        buttons_q <= shift_reg;
                        counter <= 0;
                        state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;
    -- save buttons for output
    buttons <= buttons_q;
end Behavioral;
