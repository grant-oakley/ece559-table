library ieee;
use ieee.std_logic_1164.all;

entity CAM_block is
	port(
		--input
		clk, reset: in STD_LOGIC;
		
		wr_en : in std_logic;
		wr_addr : in std_logic_vector(47 downto 0);
		wr_port : in std_logic_vector(3 downto 0);
		
		r_addr : in std_logic_vector(47 downto 0);
		--all ones if not in the table
		r_port : out std_logic_vector(3 downto 0);
		out_vld : out std_logic
		);
end CAM_block;

architecture struct of CAM_block is
signal addr_comp 			: std_logic;
signal mac_cont 			: std_logic_vector(47 downto 0);
signal r_port_buff		: std_logic_vector(3 downto 0);
component nBitRegister is
     GENERIC (n : integer := 32);
	  PORT 
           ( clock, ctrl_writeEnable, ctrl_reset    : IN STD_LOGIC;
           data_writeReg                            : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
           data_readReg                             : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
end component;

begin
comp:process(mac_cont, r_addr, r_port_buff)
begin
if(mac_cont = r_addr AND r_port_buff /= "0000" AND wr_en /= '1') then
	addr_comp <= '1';
	r_port <= r_port_buff;
else
	addr_comp <= '0';
	r_port <= "ZZZZ";
end if;
end process comp;

output_valid: out_vld <= addr_comp;
m0: nBitRegister 
	generic map(n=>48) 
	port map(clock=>clk, ctrl_writeEnable=>wr_en, ctrl_reset=>reset, data_writeReg=>wr_addr, data_readReg=>mac_cont);
p0: nBitRegister
	generic map(n=>4) 
	port map(clock=>clk, ctrl_writeEnable=>wr_en, ctrl_reset=>reset, data_writeReg=>wr_port, data_readReg=>r_port_buff);

end struct;
