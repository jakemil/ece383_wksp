----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/15/2026 05:54:03 PM
-- Design Name: 
-- Module Name: hw3 - Behavioral
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

entity hw3 is
    Port ( d : in unsigned (7 downto 0);
           h : out STD_LOGIC);
end hw3;

architecture Behavioral of hw3 is
signal s1, s2: std_logic_vector(3 downto 0);
signal input_signal: std_logic_vector(7 downto 0);

begin
    input_signal <= std_logic_vector(d);
    s1 <= input_signal(7 downto 4);
    s2 <= input_signal(3 downto 0);
    h <= '1' when (s1 = s2) else
         '0';
    


end Behavioral;
