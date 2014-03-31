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
signal out_vld_idx: std_logic_vector(31 downto 0);
signal port_bus 	: std_logic_vector(3 downto 0);
signal timeout_clr: std_logic_vector(31 downto 0);
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
		
		wr_en : in std_logic;
		wr_addr : in std_logic_vector(47 downto 0);
		wr_port : in std_logic_vector(3 downto 0);
		r_addr : in std_logic_vector(47 downto 0);
		
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
		r_port				: out std_logic_vector(3 downto 0)
		);
end component;

begin
to0: timeout port map(clk=>clk, reset=>reset, updated=>wr_idx, timed_out=>timeout_clr);
cells: 
	for i in 31 downto 0 generate
		signal wren_idx : std_logic;
		begin
			cam_block_cell: cam_block port map(clk=>clk, reset=>(reset OR timeout_clr(i)), --ADD 'AND NOT BUSY'
			wr_en=>(wr_en AND wr_idx(i)), wr_addr=>wr_addr, wr_port=>wr_port, r_addr=>r_addr,
			r_port=>port_bus, out_vld=>out_vld_idx(i));
	end generate cells;	
output: port_out_fsm port map(clk, reset, out_vld_idx, port_bus, r_en, r_vld, r_port);
conn0: r_idx <= out_vld_idx;
end struct;
