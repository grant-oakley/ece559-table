library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity port_out_fsm is
	port(
		--input
		clk, reset			: in std_logic;
		ov_idx				: in std_logic_vector(31 downto 0);
		port_bus				: in std_logic_vector(3 downto 0);
		in_vld				: in std_logic;
		
		output_valid		: out std_logic;
		r_idx					: out std_logic_vector(31 downto 0);
		r_port				: out std_logic_vector(3 downto 0)
		);
end port_out_fsm;

architecture a of port_out_fsm is
	type state is (ready_state, broadcast_state, single_port, processing_state);
	signal curr_state, next_state 	: state;
	signal port_ff_in						: std_logic_vector(3 downto 0);
	signal port_ff_out					: std_logic_vector(3 downto 0);
	signal idx_ff_out						: std_logic_vector(31 downto 0);
	signal internal_ov					: std_logic;
	signal ff_wren							: std_logic;
	component nBitRegister is
		GENERIC (n : integer := 4);
		PORT 
			( clock, ctrl_writeEnable, ctrl_reset		: IN STD_LOGIC;
           data_writeReg									: IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
           data_readReg                            : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
	end component;
	begin
	
	port_reg: nBitRegister 
			generic map(n=>4)
			port map(clock=>clk, ctrl_writeEnable=>ff_wren, ctrl_reset=>reset, data_writeReg=>port_ff_in,
				data_readReg=>port_ff_out);
	indx_reg: nBitRegister
			generic map(n=>32)
			port map(clock=>clk, ctrl_writeEnable=>ff_wren, ctrl_reset=>reset, data_writeReg=>ov_idx,
				data_readReg=>idx_ff_out);
	
	conn0: output_valid <= internal_ov;
	conn1: r_idx  <= idx_ff_out;
	conn2: r_port <= port_ff_out;
	
	--reset/clock
	process (clk, reset)
	begin
		if (reset = '1') then
			curr_state <= ready_state;
		elsif (clk'event and clk = '1') then
			curr_state <= next_state; 
		end if;
	end process;
	
	
    --Update state
	states: process (curr_state, next_state, ov_idx, in_vld, idx_ff_out)
	begin
		case (curr_state) is
			when ready_state =>	
				if in_vld = '1' then
					next_state <= processing_state;
				else 
					next_state <= ready_state;
				end if;
			when processing_state =>
				if idx_ff_out = "00000000000000000000000000000000" then
					next_state <= broadcast_state;
				else
					next_state <= single_port;
				end if;
			when broadcast_state =>
				next_state <= ready_state;
			when single_port =>
				next_state <= ready_state;
		end case;
	end process states;
	
	 --Outputs
	moore: process (curr_state, internal_ov, port_ff_in, in_vld, port_bus, ov_idx, ff_wren)
	begin
		case (curr_state) is
			when ready_state =>
				internal_ov <= '0';
				ff_wren <= '1';
				if in_vld = '1' AND ov_idx = "00000000000000000000000000000000" then
					port_ff_in <= "1111";
				elsif in_vld = '1' then
					port_ff_in <= port_bus; --save whatever is on bus 
				else
					port_ff_in <= "0000";
				end if;
			when processing_state =>
				internal_ov <= '1';
				ff_wren <= '0';
				port_ff_in <= "0000";
			when broadcast_state =>
				internal_ov <= '1';
				ff_wren <= '0';
				port_ff_in <= "0000"; --broadcast
			when single_port =>
				internal_ov <= '1';
				ff_wren <= '0';
				port_ff_in <= "0000";
		end case;
	end process moore;
 end a;