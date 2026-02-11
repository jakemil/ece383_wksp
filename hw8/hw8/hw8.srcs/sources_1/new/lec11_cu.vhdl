----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2026 09:01:50 AM
-- Design Name: 
-- Module Name: lec11_cu - Behavioral
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

entity lec11_cu is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           kbclk : in STD_LOGIC;
           sw : in STD_LOGIC;
           cw : out STD_LOGIC_VECTOR(3 downto 0);
           busy : out STD_LOGIC);
end lec11_cu;

architecture Behavioral of lec11_cu is

    type state_type is (Idle, Capture, Load);
	signal state: state_type;
	signal kbclk_prev: std_logic  := '1';
	signal kbclk_fall : std_logic;

begin
    
    kbclk_fall <= '1' when (kbclk_prev = '1' and kbclk = '0') else '0';
    -- Control Unit
    state_process: process(clk)
	 begin
		if (rising_edge(clk)) then
			if (reset = '0') then 
				state <= Idle;
				kbclk_prev <= '1';
			else
				case state is
					when Idle =>
						if (kbclk_fall = '1') then state <= Capture; end if;
				    when Capture =>
				        if (sw = '1') then state <= Load; end if;
				    when Load =>
				        state <= Idle;
				end case;
				kbclk_prev <= kbclk;
			end if;
		end if;
	end process;
	
    cw <=   "0101" when (state = Idle and kbclk_fall = '1') else
            "0011" when state = Idle else
            "1000" when state = Load else
            "0000" when (state = Capture and sw = '1') else
            "0101" when (state = Capture and kbclk_fall = '1') else
            "0000";

    busy <= '1' when (state = Capture or state = Load or (state = Idle and kbclk_fall = '1')) else '0';

end Behavioral;
