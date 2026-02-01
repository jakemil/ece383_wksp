----------------------------------------------------------------------------------
-- Lt Col James Trimble, 16-Jan-2025
-- color_mapper (previously scope face) determines the pixel color value based on the row, column, triggers, and channel inputs 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ece383_pkg.ALL;

entity color_mapper is
    Port ( color : out color_t;
           position: in coordinate_t;
		   trigger : in trigger_t;
           ch1 : in channel_t;
           ch2 : in channel_t);
end color_mapper;

architecture color_mapper_arch of color_mapper is

signal trigger_color : color_t := YELLOW; 
signal gridline_color : color_t := WHITE;
signal ch1_color : color_t := YELLOW;
signal ch2_color : color_t := GREEN;
signal background_color : color_t := BLACK;
signal hash_color : color_t := WHITE;
-- Add other colors you want to use here

signal is_vertical_gridline, is_horizontal_gridline, is_within_grid, is_trigger_time, is_trigger_volt, is_ch1_line, is_ch2_line,
    is_horizontal_hash, is_vertical_hash : boolean := false;
signal row_i, col_i : integer;
signal trig_t_i, trig_v_i : integer;

-- Fill in values here
constant grid_start_row : integer := 20;
constant grid_stop_row : integer := 420;
constant grid_start_col : integer := 20;
constant grid_stop_col : integer := 620;
constant num_horizontal_gridblocks : integer := 8;
constant num_vertical_gridblocks : integer := 10;
constant center_column : integer := 320;
constant center_row : integer := 220;
constant hash_size : integer := 5;
constant hash_horizontal_spacing : integer := 15;
constant hash_vertical_spacing : integer := 10;
constant gridline_horizontal_spacing : integer := 50;
constant gridline_vertical_spacing : integer := 60;
constant triangle_half_width : integer := 5;
constant triangle_height : integer := 5;
constant hash_half_length : integer := 2;

begin

-- Assign values to booleans here
is_horizontal_gridline <= true when((position.row - grid_start_row) mod gridline_horizontal_spacing = "0")
                          else false;
is_vertical_gridline <= true when((position.col - grid_start_col) mod gridline_vertical_spacing = "0") 
                        else false;
is_within_grid <= true when (position.row >= grid_start_row and position.row <= grid_stop_row and position.col >= grid_start_col and position.col <= grid_stop_col)
                  else false;
                  
row_i    <= to_integer(unsigned(position.row));
col_i    <= to_integer(unsigned(position.col));
trig_t_i <= to_integer(unsigned(trigger.t));
trig_v_i <= to_integer(unsigned(trigger.v));

is_trigger_time <= true when (
                   (row_i >= grid_start_row) and
                   (row_i <=  grid_start_row + triangle_height) and
                   (abs(col_i - trig_t_i) <= (triangle_half_width - (row_i - grid_start_row)))
                   ) else false;
is_trigger_volt <= true when (
                   (col_i >= grid_start_col) and
                   (col_i <=  grid_start_col + triangle_height) and
                   (abs(row_i - trig_v_i) <= (triangle_half_width - (col_i - grid_start_col)))
                   ) else false;
is_ch1_line <= true when (position.row = (440-position.col) and ch1.en = '1')
               else false;
is_ch2_line <= true when (position.row = position.col and ch2.en = '1')
               else false;
is_horizontal_hash <= true when ((position.col-grid_start_col) mod hash_horizontal_spacing = "0") and (abs(signed(position.row) - center_row) <= hash_half_length)
                      else false;
is_vertical_hash <= true when ((position.row-grid_start_row) mod hash_vertical_spacing = "0") and (abs(signed(position.col) - center_column) <= hash_half_length)
                    else false;

-- Use your booleans to choose the color
color <=        trigger_color when (is_trigger_time or is_trigger_volt) else
                gridline_color when ((is_horizontal_gridline or is_vertical_gridline) and is_within_grid) else
                ch1_color when (is_ch1_line and is_within_grid) else
                ch2_color when (is_ch2_line and is_within_grid) else
                hash_color when ((is_horizontal_hash or is_vertical_hash) and is_within_grid) else
                background_color;
                
end color_mapper_arch;
