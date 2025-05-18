library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_receiver_bt2 is
    generic (
        CLK_FREQ  : integer := 125000000;  
        BAUD_RATE : integer := 115200     
    );
    Port (
        clk_i      : in  std_logic;
        rst_i      : in  std_logic;
        rx_i       : in  std_logic;        
        rx_data_o  : out std_logic_vector(7 downto 0); 
        rx_valid_o : out std_logic        
    );
end uart_receiver_bt2;

architecture uart_rec_behavior of uart_receiver_bt2 is
    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
    
    signal rx_reg      : std_logic := '1';   
    signal rx_sync     : std_logic := '1';   
    signal clk_count   : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index   : integer range 0 to 7 := 0;
    signal rx_data_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid    : std_logic := '0';
    
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            rx_reg  <= rx_i;
            rx_sync <= rx_reg;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state <= IDLE;
                rx_data_reg <= (others => '0');
                rx_valid <= '0';
                clk_count <= 0;
                bit_index <= 0;
            else
                rx_valid <= '0';
                
                case state is
                    when IDLE =>
                        clk_count <= 0;
                        bit_index <= 0;
                        
                        if rx_sync = '0' then
                            state <= START_BIT;
                        end if;
                        
                    when START_BIT =>
                        if clk_count = (CLKS_PER_BIT - 1) / 2 then
                            if rx_sync = '0' then
                                clk_count <= 0;
                                state <= DATA_BITS;
                            else
                                state <= IDLE;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;
                        
                    when DATA_BITS =>
                        if clk_count = CLKS_PER_BIT - 1 then
                            clk_count <= 0;
                            rx_data_reg(bit_index) <= rx_sync;
                            
                            if bit_index = 7 then
                                state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;
                        
                    when STOP_BIT =>
                        if clk_count = CLKS_PER_BIT - 1 then
                            if rx_sync = '1' then
                                rx_valid <= '1';
                            end if;
                            
                            clk_count <= 0;
                            state <= IDLE;
                        else
                            clk_count <= clk_count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    rx_data_o <= rx_data_reg;
    rx_valid_o <= rx_valid;
    
end uart_rec_behavior;