------
-- Lt Col James Trimble, 15 Jan 2025
-- Generates VGA signal with graphics
------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ece383_pkg.ALL;
 
entity vga is
	Port(	clk: in  STD_LOGIC;
			reset_n : in  STD_LOGIC;
			vga : out vga_t;
            pixel : out pixel_t;
			trigger : in trigger_t;
            ch1 : in channel_t;
            ch2 : in channel_t);
end vga;


architecture vga_arch of vga is

signal position_sig: coordinate_t;
	
begin

sig_gen : entity work.vga_signal_generator
  port map(
    clk => clk,
    reset_n => reset_n,
    position => position_sig,
    vga => vga
  );
  
col_map : entity work.color_mapper
  port map(
    color => pixel.color,
    position => position_sig,
    trigger => trigger,
    ch1 => ch1,
    ch2 => ch2
  );

pixel.coordinate <= position_sig;

end vga_arch;
