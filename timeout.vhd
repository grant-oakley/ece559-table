library ieee;
use ieee.std_logic_1164.all;

entity timeout is
	port(
		--input
		clk, reset: in STD_LOGIC;		
		updated : in std_logic_vector(31 downto 0);
		--count: out std_logic_vector(33 downto 0);
		timed_out : out std_logic_vector(31 downto 0)
		);
end timeout;

architecture fsm of timeout is

component timeout_counter
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (33 DOWNTO 0)
	);
end component;

component timer_individual is
	port(
		--input
		clk, reset: IN STD_LOGIC;
		interrupt: IN STD_LOGIC;
		timed_out : OUT STD_LOGIC
		);
end component;


begin

f:
    for i in 31 downto 0 generate
    
    begin
        --timer: timeout_counter port map(reset, clk, updated(i) or timeout, test);
        --timeout <= '1' when (test = "1101111110000100011101011000000000") AND (updated(i) = '0') else '0';
        --timeout <= '1' when (test = "0000000000000000000000000000000111") AND (updated(i) /= '1') else '0';
        --timed_out(i) <= timeout;
        timer: timer_individual port map (clk, reset, updated(i), timed_out(i));
	end generate f;

--counter: timeout_counter port map (reset, clk, '0' ,count);

end fsm;