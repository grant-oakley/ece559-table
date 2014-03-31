library ieee;
use ieee.std_logic_1164.all;

entity timer_individual is
	port(
		--input
		clk, reset: IN STD_LOGIC;
		interrupt: IN STD_LOGIC;
		--countOut: OUT STD_LOGIC_VECTOR(33 downto 0);
		timed_out : OUT STD_LOGIC
		);
end timer_individual;

architecture fsm of timer_individual is

component timeout_counter
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (33 DOWNTO 0)
	);
end component;


type state_type is (S, C, T);
signal state_reg, state_next: state_type;

signal count: std_logic_vector(33 downto 0);
signal sync_reset: std_logic;

begin

counter: timeout_counter port map (reset, clk, sync_reset, count);
--countOut <= count;

process (clk,reset) -- state register update
	begin
		if (reset= '1') then state_reg <= S;
		-- asynchronous reset to state s0
		elsif (clk'event and clk = '1') then
		state_reg <= state_next;
		-- synchronous state update
		end if;
end process;

process(state_reg, interrupt, count) --next state logic
	begin
		case state_reg is
			when S =>
				if interrupt = '1' then 
					state_next <= S;
					sync_reset <= '1';
				else 
					state_next <= C;
					sync_reset <= '0';
				end if;
				timed_out <= '0';
			when C =>
				if interrupt = '1' then 
					state_next <= S;
					sync_reset <= '1';
				elsif count = "0000000000000000000000000000000111" then 
					state_next <= T;
					sync_reset <= '0';
				else state_next <= C; sync_reset <= '0';
				end if;
				timed_out <= '0';
			when T =>
				state_next <= S;
				sync_reset <= '1';
				if interrupt = '1' then timed_out <= '0';
				else timed_out <= '1';
				end if;
		end case;
end process;

--process(state_reg) -- output logic
	--begin
		--case state_reg is
			--when T =>
				--timed_out <= '1';
			--when S =>
				--timed_out <= '0';
			--when C =>
		--		timed_out <= '0';
	--	end case;
--end process;

end fsm;