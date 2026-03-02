----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/01/2026 04:47:53 PM
-- Design Name: 
-- Module Name: flag_register - Behavioral
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

entity flag_register is
    Port ( clk : in STD_LOGIC;
           reset_n : in STD_LOGIC;
           set : in STD_LOGIC;
           clear : in STD_LOGIC;
           Q : out STD_LOGIC);
end flag_register;

architecture Behavioral of flag_register is
signal q_sig : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                q_sig <= '0';
            else
                --implement the table from lab writeup
                case (set & clear) is
                  when "00" => 
                     q_sig <= q_sig;
                  when "01" =>
                     q_sig <= '0';
                  when "10" =>
                     q_sig <= '1';
                  when "11" =>
                     q_sig <= 'X';
                  when others =>
                     q_sig <= q_sig;
                end case;
            end if;
        end if;
    end process;
    Q <= q_sig;
end Behavioral;
