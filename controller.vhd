library ieee;
use ieee.std_logic_1164.all;

entity controller is
	port (
        clock, reset : in std_logic;
    
        --forwarding interface
        src_addr : in std_logic_vector(47 downto 0);
        dest_addr : in std_logic_vector(47 downto 0);
        r_port : in std_logic_vector(3 downto 0);
        data_vld : in std_logic;
        
        port_num : out std_logic_vector(3 downto 0);
        port_vld : out std_logic;
        
        
        --lru interface
        lru_en : out STD_LOGIC;
		lru_wr_en : out STD_LOGIC;
		lru_read_idx : out STD_LOGIC_VECTOR(31 downto 0);
		
		lru_write_idx: in STD_LOGIC_VECTOR(31 downto 0);
		lru_vld: in STD_LOGIC;
		
		
		--CAM interface
		cam_wr_en : out std_logic;
		cam_wr_idx : out std_logic_vector(4 downto 0);
		cam_wr_addr : out std_logic_vector(47 downto 0);
		cam_wr_port : out std_logic_vector(3 downto 0);
		
		cam_r_addr : out std_logic_vector(47 downto 0);
		--all ones if not in the table
		cam_r_port : in std_logic_vector(3 downto 0);
		--index the value was read from
		cam_r_idx : in std_logic_vector(31 downto 0)
    );
end controller;

architecture fsm of controller is
begin



end fsm;