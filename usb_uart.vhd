library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity usb_uart is
    Generic (
        CLK_FREQ  : integer := 125000000;
        BAUD_RATE : integer := 9600
    );
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        rx        : in  std_logic;
        data_out  : out std_logic_vector(7 downto 0);
        data_valid: out std_logic
    );
end usb_uart;

architecture usb_uart_behavior of usb_uart is
    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    type rx_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal rx_state : rx_state_t := IDLE;
    
    signal rx_sync      : std_logic_vector(1 downto 0) := (others => '1');
    signal clk_counter  : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal bit_index    : integer range 0 to 7 := 0;
    signal rx_data      : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data_valid: std_logic := '0';

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
            if rst = '1' then
                rx_state <= IDLE;
                rx_data_valid <= '0';
                clk_counter <= 0;
                bit_index <= 0;
                rx_data <= (others => '0');
            else
                rx_data_valid <= '0';
                
                case rx_state is
                    when IDLE =>
                        if rx_sync(1) = '0' then
                            rx_state <= START_BIT;
                            clk_counter <= 0;
                        end if;
                        
                    when START_BIT =>
                        if clk_counter = CLKS_PER_BIT/2 then
                            if rx_sync(1) = '0' then
                                rx_state <= DATA_BITS;
                                clk_counter <= 0;
                                bit_index <= 0;
                            else
                                rx_state <= IDLE;
                            end if;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;
                        
                    when DATA_BITS =>
                        if clk_counter = CLKS_PER_BIT-1 then
                            rx_data(bit_index) <= rx_sync(1);
                            clk_counter <= 0;
                            
                            if bit_index = 7 then
                                rx_state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;
                        
                    when STOP_BIT =>
                        if clk_counter = CLKS_PER_BIT-1 then
                            rx_data_valid <= '1';
                            rx_state <= IDLE;
                            clk_counter <= 0;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;
                        
                end case;
            end if;
        end if;
    end process;
    
    data_out <= rx_data;
    data_valid <= rx_data_valid;
    
end usb_uart_behavior;