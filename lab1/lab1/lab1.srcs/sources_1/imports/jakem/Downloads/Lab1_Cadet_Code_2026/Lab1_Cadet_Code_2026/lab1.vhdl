----------------------------------------------------------------------------------
--	Title
--  Name
--  Description
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ece383_pkg.ALL;

entity lab1 is
    Port ( clk : in  STD_LOGIC;
           reset_n : in  STD_LOGIC;
		   btn: in	STD_LOGIC_VECTOR(4 downto 0);
		   sw: in STD_LOGIC_VECTOR(1 downto 0);
           tmds : out  STD_LOGIC_VECTOR (3 downto 0);
           tmdsb : out  STD_LOGIC_VECTOR (3 downto 0));
end lab1;

architecture structure of lab1 is

    constant CENTER : integer := 0;
    constant DOWN : integer := 1;
    constant LEFT : integer := 2;
    constant RIGHT : integer := 3;
    constant UP : integer := 4;

    signal trigger: trigger_t;
	signal pixel: pixel_t;
	signal ch1, ch2: channel_t;
	signal time_trigger_value, volt_trigger_value : signed(10 downto 0);
begin
   
-- Add numeric steppers for time and voltage trigger
row_stepper : entity work.numeric_stepper
  generic map(
    num_bits  => 11,
    max_value => 420,
    min_value => 20,
    delta     => 10
  )
  port map(
    clk     => clk,
    reset_n => reset_n,                   -- active-low synchronous reset
    en      => '1',                   -- enable
    up      => btn(UP),                    -- increment on rising edge
    down    => btn(DOWN),                    -- decrement on rising edge
    q       => volt_trigger_value   -- signed output
  );
  
column_counter : entity work.numeric_stepper
  generic map(
    num_bits  => 11,
    max_value => 620,
    min_value => 20,
    delta     => 10
  )
  port map(
    clk     => clk,
    reset_n => reset_n,                   -- active-low synchronous reset
    en      => '1',                   -- enable
    up      => btn(RIGHT),                    -- increment on rising edge
    down    => btn(LEFT),                    -- decrement on rising edge
    q       => time_trigger_value   -- signed output
  );
-- Assign trigger.t and trigger.v
trigger.t <= unsigned(time_trigger_value);
trigger.v <= unsigned(volt_trigger_value);
-- Instantiate video
 vid : entity work.video
    port map(  clk => clk,
            reset_n => reset_n,
            tmds => tmds,
            tmdsb => tmdsb,
            trigger => trigger,
            position => pixel.coordinate,
            ch1 => ch1,
            ch2 => ch2
    );
-- Determine if ch1 and or ch2 are active
ch1.active <= '1' when pixel.coordinate.row = pixel.coordinate.col else '0';
ch2.active <= '1' when (440-pixel.coordinate.row) = pixel.coordinate.col else '0';
-- Connect board hardware to signals
ch1.en <= sw(0);
ch2.en <= sw(1);
end structure;
