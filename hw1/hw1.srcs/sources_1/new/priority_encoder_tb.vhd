----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/08/2026 11:22:31 PM
-- Design Name: 
-- Module Name: priority_encoder_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity priority_encoder_tb is
--  Port ( );
end priority_encoder_tb;

architecture Behavioral of priority_encoder_tb is

    -- Component declaration
    component priority_encoder
        Port (
            I0 : in  STD_LOGIC;
            I1 : in  STD_LOGIC;
            I2 : in  STD_LOGIC;
            I3 : in  STD_LOGIC;
            O1 : out STD_LOGIC;
            O0 : out STD_LOGIC
        );
    end component;

    -- Testbench signals
    signal I0 : STD_LOGIC := '0';
    signal I1 : STD_LOGIC := '0';
    signal I2 : STD_LOGIC := '0';
    signal I3 : STD_LOGIC := '0';
    signal O1 : STD_LOGIC;
    signal O0 : STD_LOGIC;

begin

    -- Instantiate the DUT (Device Under Test)
    DUT: priority_encoder
        port map (
            I0 => I0,
            I1 => I1,
            I2 => I2,
            I3 => I3,
            O1 => O1,
            O0 => O0
        );

    -- Stimulus process
    stim_proc: process
    begin
    -- Apply all input combinations (I0 = LSB, I3 = MSB)
    I0 <= '0'; I1 <= '0'; I2 <= '0'; I3 <= '0'; wait for 10 ns; -- 0000
    I0 <= '1'; I1 <= '0'; I2 <= '0'; I3 <= '0'; wait for 10 ns; -- 0001
    I0 <= '0'; I1 <= '1'; I2 <= '0'; I3 <= '0'; wait for 10 ns; -- 0010
    I0 <= '1'; I1 <= '1'; I2 <= '0'; I3 <= '0'; wait for 10 ns; -- 0011
    
    I0 <= '0'; I1 <= '0'; I2 <= '1'; I3 <= '0'; wait for 10 ns; -- 0100
    I0 <= '1'; I1 <= '0'; I2 <= '1'; I3 <= '0'; wait for 10 ns; -- 0101
    I0 <= '0'; I1 <= '1'; I2 <= '1'; I3 <= '0'; wait for 10 ns; -- 0110
    I0 <= '1'; I1 <= '1'; I2 <= '1'; I3 <= '0'; wait for 10 ns; -- 0111
    
    I0 <= '0'; I1 <= '0'; I2 <= '0'; I3 <= '1'; wait for 10 ns; -- 1000
    I0 <= '1'; I1 <= '0'; I2 <= '0'; I3 <= '1'; wait for 10 ns; -- 1001
    I0 <= '0'; I1 <= '1'; I2 <= '0'; I3 <= '1'; wait for 10 ns; -- 1010
    I0 <= '1'; I1 <= '1'; I2 <= '0'; I3 <= '1'; wait for 10 ns; -- 1011
    
    I0 <= '0'; I1 <= '0'; I2 <= '1'; I3 <= '1'; wait for 10 ns; -- 1100
    I0 <= '1'; I1 <= '0'; I2 <= '1'; I3 <= '1'; wait for 10 ns; -- 1101
    I0 <= '0'; I1 <= '1'; I2 <= '1'; I3 <= '1'; wait for 10 ns; -- 1110
    I0 <= '1'; I1 <= '1'; I2 <= '1'; I3 <= '1'; wait for 10 ns; -- 1111

        -- End simulation
        wait;
    end process;
    
end Behavioral;
