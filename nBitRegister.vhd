LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY nBitRegister IS
    GENERIC (n : INTEGER := 32);
	PORT ( clock, ctrl_writeEnable, ctrl_reset : IN STD_LOGIC;
	       data_writeReg : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
	       data_readReg : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0) );
END nBitRegister;

ARCHITECTURE Structure OF nBitRegister IS
    COMPONENT DFFE
       PORT (d   : IN STD_LOGIC;
             clk  : IN STD_LOGIC;
             clrn : IN STD_LOGIC;
             prn  : IN STD_LOGIC;
             ena  : IN STD_LOGIC;
             q    : OUT STD_LOGIC );
    END COMPONENT;
BEGIN
    G0: FOR i IN 0 TO n-1 GENERATE
        dFFs: DFFE PORT MAP (data_writeReg(i), clock, NOT ctrl_reset, '1', 
                             ctrl_writeEnable, data_readReg(i));
    END GENERATE;
END Structure;