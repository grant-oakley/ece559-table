library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lru is
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
end lru;

architecture structure of lru is

    type state_type is (ready, search, valid);
    signal curr_state, next_state   : state_type;
    
    signal flags_in                 : std_logic_vector(31 downto 0);
    signal flags_out                : std_logic_vector(31 downto 0);
    
    signal clock_idx                : std_logic_vector(31 downto 0);
    signal en_clock                 : std_logic;
    signal wrap_around              : std_logic;
    
    signal valid_cells              : std_logic_vector(31 downto 0);
    signal has_valid                : std_logic;
    
    component lru_shiftreg
        PORT
        (
            aset		: IN STD_LOGIC ;
            clock		: IN STD_LOGIC ;
            enable		: IN STD_LOGIC ;
            shiftin		: IN STD_LOGIC ;
            q		    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
            shiftout	: OUT STD_LOGIC 
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

    set_outputs: write_idx <= clock_idx;
    clock_hand: lru_shiftreg port map(reset, clk, en_clock and not has_valid, 
                                      wrap_around, clock_idx, wrap_around);
    flag_reg: nBitRegister port map(clk, '1', reset, flags_in, flags_out);
    find_valid:
        for i in 31 downto 0 generate
            --High if pointed to by clock hand, and was not recently used
            g0: valid_cells(i) <= (not flags_out(i)) and clock_idx(i);
        end generate;

    --Reset and advance state
    process (clk, reset)
    begin
        if (reset = '1') then
            curr_state <= ready;
        elsif (clk'event and clk = '1') then
            curr_state <= next_state;
        end if;
    end process;
    
    --Update state
    process (curr_state, en, wr_en, has_valid)
    begin
        case curr_state is
            when ready =>
                if (en='1' and wr_en='1') then
                    next_state <= search;
                else
                    next_state <= ready;
                end if;
            when search =>
                if (has_valid = '1') then
                    next_state <= valid;
                else
                    next_state <= search;
                end if;
            when valid =>
                next_state <= ready;
        end case;
    end process;
    
    --Set Moore outputs
    process (curr_state)
    begin
        case curr_state is
            when ready =>
                vld <= '0';
                en_clock <= '0';
            when search =>
                vld <= '0';
                en_clock <= '1';
            when valid =>
                vld <= '1';
                en_clock <= '0';
        end case;
    end process;
    
    --Set has_valid signal
    process (valid_cells)
    begin
        if (valid_cells /= "00000000000000000000000000000000") then
            has_valid <= '1';
        else
            has_valid <= '0';
        end if;
    end process;
    
    --Update flags
    process (curr_state, en, wr_en, read_idx, flags_in, flags_out, clock_idx)
    begin
        for i in 31 downto 0 loop
            if (curr_state = search and clock_idx(i) = '1') then
                flags_in(i) <= '0';
            elsif ((curr_state = ready and en = '1' and wr_en = '0' and read_idx(i) = '1')
                        or (curr_state = valid and clock_idx(i) = '1')) then
                flags_in(i) <= '1';
            else
                flags_in(i) <= flags_out(i);
            end if;
        end loop;
    end process;
    
end structure;