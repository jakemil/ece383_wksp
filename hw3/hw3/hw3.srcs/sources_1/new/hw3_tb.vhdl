----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/15/2026 05:54:03 PM
-- Design Name: 
-- Module Name: hw3_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hw3_tb is
--  Port ( );
end hw3_tb;

architecture Behavioral of hw3_tb is

    -- Component declaration for the DUT (Device Under Test)
    component hw3
        Port (
            d : in unsigned (7 downto 0);
            h : out std_logic
        );
    end component;

    -- Testbench signals
    signal d_tb : unsigned(7 downto 0) := (others => '0');
    signal h_tb : std_logic;

begin

    -- Instantiate the DUT
    uut: hw3
        port map (
            d => d_tb,
            h => h_tb
        );

    -- Stimulus process
    stim_proc: process
        variable i : integer;
    begin
        for i in 0 to 255 loop
            d_tb <= to_unsigned(i, 8);
            wait for 10 ns;
    
            if (i mod 17 = 0) then
                assert h_tb = '1'
                    report "FAIL: " & integer'image(i) &
                           " is a multiple of 17 but h /= '1'"
                    severity error;
            else
                assert h_tb = '0'
                    report "FAIL: " & integer'image(i) &
                           " is NOT a multiple of 17 but h /= '0'"
                    severity error;
            end if;
        end loop;
    
        report "All multiples-of-17 tests passed" severity note;
        wait;
    end process;

end Behavioral;
