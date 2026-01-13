----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/12/2026 04:41:02 PM
-- Design Name: 
-- Module Name: scancode_decoder_tb - Behavioral
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

entity scancode_decoder_tb is
--  Port ( );
end scancode_decoder_tb;

architecture Behavioral of scancode_decoder_tb is
    
    component scancode_decoder
        Port (
           scancode : in STD_LOGIC_VECTOR (7 downto 0);
           decoded_value : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    
    signal scancode : STD_LOGIC_VECTOR (7 downto 0) := x"45";
    signal decoded_value : STD_LOGIC_VECTOR (3 downto 0) := "0000";
            

begin

    DUT: scancode_decoder
        port map (
            scancode => scancode,
            decoded_value => decoded_value
        );

    stim_proc: process
    begin
    scancode <= x"45"; wait for 10 ns;
    scancode <= x"16"; wait for 10 ns;
    scancode <= x"1E"; wait for 10 ns;
    scancode <= x"26"; wait for 10 ns;
    scancode <= x"25"; wait for 10 ns;
    scancode <= x"2E"; wait for 10 ns;
    scancode <= x"36"; wait for 10 ns;
    scancode <= x"3D"; wait for 10 ns;
    scancode <= x"3E"; wait for 10 ns;
    scancode <= x"46"; wait for 10 ns;

        wait;
    end process;

end Behavioral;
