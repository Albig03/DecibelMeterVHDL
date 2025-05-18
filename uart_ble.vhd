library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_ble is
    Generic (
        CLK_FREQ    : integer := 125_000_000;
        BAUD_RATE   : integer := 115200
    );
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        rx          : in  std_logic;
        data_out    : out std_logic_vector(7 downto 0);
        data_valid  : out std_logic
    );
end uart_ble;

architecture uart_rx_behavior of uart_ble is
    constant BIT_PERIOD  : integer := CLK_FREQ / BAUD_RATE;
    constant HALF_PERIOD : integer := BIT_PERIOD / 2;
    
    type uart_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state         : uart_state_t := IDLE;
    
    signal bit_timer     : integer range 0 to BIT_PERIOD-1 := 0;
    signal bit_counter   : integer range 0 to 7 := 0;
    signal rx_data       : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_sync       : std_logic_vector(1 downto 0) := (others => '1');
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            rx_sync <= rx_sync(0) & rx;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            data_valid <= '0';
            
            if rst = '1' then
                state <= IDLE;
                bit_timer <= 0;
                bit_counter <= 0;
                rx_data <= (others => '0');
            else
                case state is
                    when IDLE =>
                        if rx_sync(1) = '1' and rx_sync(0) = '0' then
                            state <= START_BIT;
                            bit_timer <= 0;
                        end if;
                        
                    when START_BIT =>
                        if bit_timer = HALF_PERIOD then
                            if rx_sync(1) = '0' then
                                state <= DATA_BITS;
                                bit_timer <= 0;
                                bit_counter <= 0;
                            else
                                state <= IDLE;
                            end if;
                        else
                            bit_timer <= bit_timer + 1;
                        end if;
                        
                    when DATA_BITS =>
                        if bit_timer = BIT_PERIOD-1 then
                            rx_data(bit_counter) <= rx_sync(1);
                            bit_timer <= 0;
                            
                            if bit_counter = 7 then
                                state <= STOP_BIT;
                            else
                                bit_counter <= bit_counter + 1;
                            end if;
                        else
                            bit_timer <= bit_timer + 1;
                        end if;
                        
                    when STOP_BIT =>
                        if bit_timer = BIT_PERIOD-1 then
                            if rx_sync(1) = '1' then
                                data_out <= rx_data;
                                data_valid <= '1';
                            end if;
                            
                            state <= IDLE;
                        else
                            bit_timer <= bit_timer + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
end uart_rx_behavior;