-- vga_signal_generator Generates the hsync, vsync, blank, and row, col for the VGA signal

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ece383_pkg.ALL;

entity vga_signal_generator is
    Port ( clk : in STD_LOGIC;
           reset_n : in STD_LOGIC;
           position: out coordinate_t;
           vga : out vga_t);
end vga_signal_generator;

architecture vga_signal_generator_arch of vga_signal_generator is

    signal horizontal_roll, vertical_roll: std_logic := '0';		
    signal h_counter_ctrl, v_counter_ctrl: std_logic := '1'; -- Default to counting up
    signal h_sync_is_low, v_sync_is_low, h_blank_is_low, v_blank_is_low : boolean := false;
    signal current_pos : coordinate_t;
begin

-- horizontal counter
horizontal_counter : counter
    generic map(
            num_bits => 10,
            max_value => 799
    )
    Port map ( 
           clk => clk,
           reset_n => reset_n,
           ctrl => h_counter_ctrl,
           roll => horizontal_roll,
           Q => current_pos.col
    );
-- Glue code to connect the horizontal and vertical counters
v_counter_ctrl <= horizontal_roll;
-- vertical counter
vertical_counter : counter
    generic map(
            num_bits => 10,
            max_value => 524
    )
    Port map ( 
           clk => clk,
           reset_n => reset_n,
           ctrl => v_counter_ctrl,
           roll => vertical_roll,
           Q => current_pos.row
    );
-- Assign VGA outputs in a gated manner
process (clk)
begin
   if rising_edge(clk) then
        if reset_n = '0' then
            vga.hsync <= '1';
            vga.vsync <= '1';
            vga.blank <= '0';
            
        else
            vga.hsync <= vga.hsync;
            vga.vsync <= vga.vsync;
            vga.blank <= vga.blank;
            if current_pos.col = 639 then
                vga.blank <= '1';
                vga.hsync <= '1';
            elsif current_pos.col = 655 then
                vga.hsync <= '0';
            elsif current_pos.col = 751 then
                vga.hsync <= '1';
            elsif current_pos.col = 799 then
                vga.blank <= '0';
            end if;
            
            if current_pos.row = 479 then
                vga.vsync <= '1';
                vga.blank <= '1';
            elsif current_pos.row = 489 then
                vga.vsync <= '0';
            elsif current_pos.row = 491 then
                vga.vsync <= '1';
            elsif current_pos.row = 524 then
                vga.blank <= '0';
            end if;
        end if;
    end if;
end process;

-- Assign output ports
position.row <= current_pos.row;
position.col <= current_pos.col;

end vga_signal_generator_arch;
