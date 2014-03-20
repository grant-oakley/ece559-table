LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity table is
    port (
        clock, reset : in std_logic;
    
        src_addr : in std_logic_vector(47 downto 0);
        dest_addr : in std_logic_vector(47 downto 0);
        r_port : in std_logic_vector(3 downto 0);
        data_vld : in std_logic;
        
        port_num : out std_logic_vector(3 downto 0);
        port_vld : out std_logic
    );
end table;
    
architecture struct of table is
begin


end struct;