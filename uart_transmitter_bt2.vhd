library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_transmitter_bt2 is
    generic (
        CLK_FREQ  : integer := 125000000; 
        BAUD_RATE : integer := 115200        
    );
    Port (
        clk_i      : in  std_logic;
        rst_i      : in  std_logic;
        tx_data_i  : in  std_logic_vector(7 downto 0);
        tx_start_i : in  std_logic;        
        tx_busy_o  : out std_logic;       
        tx_o       : out std_logic       
    );
end uart_transmitter_bt2;

architecture uart_trans_behavior of uart_transmitter_bt2 is
    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
    
    signal clk_count   : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index   : integer range 0 to 7 := 0;
    signal tx_data_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy     : std_logic := '0';
    signal tx_bit      : std_logic := '1';  
    
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state <= IDLE;
                tx_data_reg <= (others => '0');
                tx_busy <= '0';
                tx_bit <= '1';  
                clk_count <= 0;
                bit_index <= 0;
            else
                case state is
                    when IDLE =>
                        tx_bit <= '1'; 
                        tx_busy <= '0';
                        clk_count <= 0;
                        bit_index <= 0;
                        
                        if tx_start_i = '1' then
                            tx_data_reg <= tx_data_i; 
                            tx_busy <= '1';
                            state <= START_BIT;
                        end if;
                        
                    when START_BIT =>
                        tx_bit <= '0';  
                        
                        if clk_count = CLKS_PER_BIT - 1 then
                            clk_count <= 0;
                            state <= DATA_BITS;
                        else
                            clk_count <= clk_count + 1;
                        end if;
                        
                    when DATA_BITS =>
                        tx_bit <= tx_data_reg(bit_index); 
                        
                        if clk_count = CLKS_PER_BIT - 1 then
                            clk_count <= 0;
                            
                            if bit_index = 7 then
                                state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;
                        
                    when STOP_BIT =>
                        tx_bit <= '1';  
                        
                        if clk_count = CLKS_PER_BIT - 1 then
                            state <= IDLE;
                        else
                            clk_count <= clk_count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    tx_o <= tx_bit;
    tx_busy_o <= tx_busy;
    
end uart_trans_behavior;