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
		  
		  debug_state: out std_LOGIC_VECTOR(2 downto 0)
    );
end controller;

architecture fsm of controller is

	component lru 
		port(
			--input
			clk, reset      : in STD_LOGIC;
		
			en              : in STD_LOGIC;
			--(1,write) /(0,read) 
			wr_en           : in STD_LOGIC;
			read_idx        : in STD_LOGIC_VECTOR(31 downto 0);
		
			--output
			write_idx       : out STD_LOGIC_VECTOR(31 downto 0);
			vld             : out STD_LOGIC
			);
	end component;
	
	component CAM 
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
	end component;


    component nBitRegister is
        GENERIC (n : integer := 52);
        PORT 
           ( clock, ctrl_writeEnable, ctrl_reset    : IN STD_LOGIC;
           data_writeReg                            : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
           data_readReg                             : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
    end component;
    

type state_type is (idle, latch_src_lookup_dest,wait_lookup_res, output_ready, query_src_addr, query_LRU, wait_LRU_res, update_CAM);
signal current_state, next_state: state_type;

--register signals
signal REG_write_en 		:std_logic;
signal REG_1_write_en   :std_logic;

signal REG_out              :std_logic_vector(51 downto 0);
signal REG_1_in				 :std_logic_vector(31 downto 0);
signal REG_1_out				 :std_logic_vector(31 downto 0);

--CAM signals
signal CAM_read_en			:std_logic;
signal CAM_write_en			:std_logic;
signal CAM_write_idx 		:std_logic_vector(31 downto 0);
signal CAM_write_addr 		:std_logic_vector(47 downto 0);
signal CAM_read_addr		:std_logic_vector(47 downto 0);
signal CAM_write_port 		:std_logic_vector(3 downto 0);
--CAM output signals
signal CAM_read_output_valid:std_logic;
signal CAM_port_out			:std_logic_vector(3 downto 0);
signal CAM_idx_out			:std_logic_vector(31 downto 0);

--LRU signals
signal LRU_en				:std_logic;
signal LRU_write_en			:std_logic;
--signal LRU_recently_used	:std_logic_vector(31 downto 0);
--output
signal LRU_freed_index		:std_logic_vector(31 downto 0);
signal LRU_valid			:std_logic;

begin


lru_0: lru port map(clock, reset, LRU_en, LRU_write_en, CAM_idx_out, LRU_freed_index, LRU_valid);
reg_0: nBitRegister port map(clock, REG_write_en, reset, src_addr & r_port ,REG_out);
reg_1: nBitRegister generic map(n => 32) port map(clock, REG_1_write_en, reset, REG_1_in ,REG_1_out);
cam_0: CAM port map(clock, reset, CAM_read_en, CAM_write_en, CAM_write_idx, CAM_write_addr, CAM_write_port, CAM_read_addr, CAM_port_out, CAM_idx_out, CAM_read_output_valid);

port_num <= CAM_port_out;

process (clock,reset) -- state register update
	begin
		if (reset= '1') then current_state <= idle;
		-- asynchronous reset to state s0
		elsif (clock'event and clock = '1') then
		current_state <= next_state;
		-- synchronous state update
		end if;
end process;


process(current_state, data_vld, CAM_read_output_valid) 
	begin
		case current_state is
			when idle =>
				if data_vld = '1' then
					next_state <= latch_src_lookup_dest;
				else 
					next_state <= idle;
				end if;
				
				--default signals
				debug_state<= "001";
				port_vld <= '0';
				CAM_read_en <= '0';
				CAM_write_en <= '0';
				LRU_en <='0';
				REG_1_write_en <= '0';
			when latch_src_lookup_dest =>
				REG_write_en <= '1';
				CAM_read_addr <= dest_addr;
				CAM_read_en <='1';
				next_state <= wait_lookup_res;
				
				--default signals
				debug_state <= "010";
				port_vld <= '0';
				LRU_en <= '0';
				CAM_write_en <= '0';
				REG_1_write_en <= '0';
			when wait_lookup_res =>
				if CAM_read_output_valid ='1' then
					next_state <= output_ready;
				else
					next_state <= wait_lookup_res;
				end if;
								
				--default signals
				debug_state<= "011";
				port_vld <= '0';
				LRU_en <= '0';
				CAM_read_en <= '0';
				CAM_write_en <= '0';
				REG_1_write_en <= '0';
			when output_ready =>
				if CAM_port_out /= "1111" then
					LRU_write_en <= '0';
					LRU_en <= '1';
				else
					LRU_en <='0';
				end if;
				next_state <= query_src_addr;
				
				--default signals
				debug_state<= "100";
				port_vld <= '1';
				CAM_read_en <= '0';
				CAM_write_en <= '0';
				REG_1_write_en <= '0';
			when query_src_addr =>
				CAM_read_addr <= REG_out(51 downto 4);
				CAM_read_en <='1';
				CAM_write_en <= '0';
				
				if CAM_read_output_valid ='1' and CAM_port_out = "1111" then
					next_state <= query_LRU;
				elsif CAM_read_output_valid ='1' and CAM_port_out /= "1111" then
					REG_1_write_en <= '1';
					REG_1_in <= CAM_idx_out;
					next_state <= update_CAM;
				end if;
				--default signals
				debug_state<= "101";
				LRU_en <= '0';
				port_vld <= '0';	
			when query_LRU =>
				LRU_write_en <= '1';
				LRU_en <= '1';
				next_state <= wait_LRU_res;
				
				--default signals
				debug_state<= "110";
				port_vld <= '0';
				CAM_read_en <= '0';
				CAM_write_en <= '0';
				REG_1_write_en <= '0';
			when wait_LRU_res =>
				if LRU_valid = '1' then
					REG_1_write_en <= '1';
					REG_1_in <= LRU_freed_index;
					next_state <= update_CAM;
				else
					next_state <= wait_LRU_res;
				end if;
				LRU_en <= '0';
				--default signals
				debug_state<= "110";
				port_vld <= '0';
				CAM_read_en <= '0';
				CAM_write_en <= '0';
			when update_CAM =>
				CAM_write_en <= '1';
				CAM_write_idx <= REG_1_in;
				CAM_write_addr <= REG_out(51 downto 4);
				CAM_write_port <= REG_out(3 downto 0);
				LRU_en <= '0';
				next_state <= idle;
				
				--default signals
				debug_state<= "111";
				port_vld <= '0';
				CAM_read_en <= '0';
				REG_1_write_en <= '0';
		end case;
end process;	
				
end fsm;