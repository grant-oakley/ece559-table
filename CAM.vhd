library ieee;
use ieee.std_logic_1164.all;

entity CAM is
	port(
		--input
		clk, reset: in std_logic;
		
		r_en : in std_logic; --read enable
		wr_en : in std_logic; --write enable
		wr_idx : in std_logic_vector(31 downto 0);
		wr_addr : in std_logic_vector(47 downto 0);
		wr_port : in std_logic_vector(3 downto 0);
		
		r_addr : in std_logic_vector(47 downto 0);
		--all ones if not in the table
		r_port : out std_logic_vector(3 downto 0);
		--index the value was read from
		r_idx : out std_logic_vector(31 downto 0);
		r_vld : out std_logic
		);
end CAM;

architecture struct of CAM is
type state is (input_state, read_state, write_state);
signal curr_state, next_state 	: state;

signal out_vld_idx: std_logic_vector(31 downto 0);
signal port_bus 	: std_logic_vector(3 downto 0);
signal timeout_clr: std_logic_vector(31 downto 0);

signal block_wr_en	: std_logic;
signal block_r_en		: std_logic;

signal r_addr_ff 		: std_logic_vector(47 downto 0);
signal wr_idx_ff		: std_logic_vector(31 downto 0);
signal wr_port_ff		: std_logic_vector(3 downto 0);
signal wr_addr_ff		: std_logic_vector(47 downto 0);
component timeout is
	port(
		--input
		clk, reset: in std_logic;
		
		updated : in std_logic_vector(31 downto 0);
		timed_out : out std_logic_vector(31 downto 0)
		);
end component;

component CAM_block is
	port(
		--input
		clk, reset: in std_logic;
		
		wr_en 	: in std_logic;
		wr_addr 	: in std_logic_vector(47 downto 0);
		wr_port 	: in std_logic_vector(3 downto 0);
		r_en		: in std_logic;
		r_addr 	: in std_logic_vector(47 downto 0);
		
		--all ones if not in the table
		r_port : out std_logic_vector(3 downto 0);
		out_vld : out std_logic
		);
end component;

component port_out_fsm is
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
end component;
component nBitRegister is
     GENERIC (n : integer := 32);
	  PORT 
           ( clock, ctrl_writeEnable, ctrl_reset    : IN STD_LOGIC;
           data_writeReg                            : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
           data_readReg                             : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
end component;

begin
to0: timeout port map(clk=>clk, reset=>reset, updated=>wr_idx, timed_out=>timeout_clr);
r_addr_reg: nbitRegister
			generic map(n=>48)
			port map(clk, r_en, reset, r_addr, r_addr_ff);
wr_addr_reg: nbitRegister
			generic map(n=>48)
			port map(clk, wr_en, reset, wr_addr, wr_addr_ff);
wr_port_reg: nbitRegister
			generic map(n=>4)
			port map(clk, wr_en, reset, wr_port, wr_port_ff);
wr_idx_reg: nbitRegister
			generic map(n=>32)
			port map(clk, wr_en, reset, wr_idx, wr_idx_ff);			
			
cells: 
	for i in 31 downto 0 generate
		signal wren_idx : std_logic;
		begin
			cam_block_cell: cam_block port map(clk=>clk, reset=>((reset) OR timeout_clr(i)), --ADD 'AND NOT BUSY'
			wr_en=>(block_wr_en AND wr_idx_ff(i)), wr_addr=>wr_addr_ff, wr_port=>wr_port_ff, r_en=>block_r_en, r_addr=>r_addr_ff,
			r_port=>port_bus, out_vld=>out_vld_idx(i));
	end generate cells;	
output: port_out_fsm port map(clk, reset, out_vld_idx, port_bus, block_r_en, r_vld, r_idx, r_port);

	--reset/clock
	process (clk, reset)
	begin
		if (reset = '1') then
			curr_state <= input_state;
		elsif (clk'event and clk = '1') then
			curr_state <= next_state; 
		end if;
	end process;
	
	   --Update state
	states: process (curr_state, next_state, wr_en, r_en)
	begin
		case (curr_state) is
			when input_state =>	
				if wr_en = '1' then
					next_state <= write_state;
				elsif r_en = '1' then 
					next_state <= read_state;
				else 
					next_state <= input_state;
				end if;
			when read_state =>
				next_state <= input_state;
			when write_state =>
				next_state <= input_state;
		end case;
	end process states;
	
	 --Outputs
	moore: process (curr_state, block_r_en, block_wr_en)
	begin
		case (curr_state) is
			when input_state =>
				block_r_en <= '0';
				block_wr_en <= '0';
			when write_state =>
				block_wr_en <= '1';
				block_r_en <= '0';
			when read_state =>
				block_wr_en <= '0';
				block_r_en <= '1';
		end case;
	end process moore;
end struct;
