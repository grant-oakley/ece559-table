library ieee;
use ieee.std_logic_1164.all;

entity CAM is
	port(
		--input
		clk, reset: in std_logic;
		
		wr_en : in std_logic;
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
		clk, reset: in STD_LOGIC;
		
		wr_en : in std_logic;
		wr_addr : in std_logic_vector(47 downto 0);
		wr_port : in std_logic_vector(3 downto 0);
		r_addr : in std_logic_vector(47 downto 0);
		
		--all ones if not in the table
		r_port : out std_logic_vector(3 downto 0);
		out_valid : out std_logic
		);
end component;
begin

end struct;
