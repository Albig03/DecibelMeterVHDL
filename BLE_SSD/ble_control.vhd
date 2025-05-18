library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ble_control is
    Generic (
        CLK_FREQ    : integer := 125_000_000
    );
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        ble_reset   : out std_logic;
        ble_rts     : out std_logic;
        ble_tx      : out std_logic;
        ble_rx      : in  std_logic;
        btn_reset   : in  std_logic;
        btn_cmd     : in  std_logic;
        led_status  : out std_logic_vector(1 downto 0)
    );
end ble_control;

architecture ble_ctrl_behavior of ble_control is
    type ble_state_t is (
        STATE_RESET,
        STATE_WAIT_RESET,
        STATE_NORMAL,
        STATE_CMD_ENTRY,
        STATE_CMD_SEND_DISC,
        STATE_CMD_SEND_REBOOT
    );
    
    signal state          : ble_state_t := STATE_RESET;
    signal counter        : integer range 0 to CLK_FREQ * 5 := 0;
    signal uart_tx_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_valid  : std_logic := '0';
    signal uart_tx_ready  : std_logic := '1';
    signal cmd_sequence   : integer range 0 to 15 := 0;
    signal btn_reset_prev : std_logic := '0';
    signal btn_cmd_prev   : std_logic := '0';
    
    signal bit_counter    : integer range 0 to 10 := 0;
    signal bit_timer      : integer range 0 to CLK_FREQ / 115200 := 0;
    signal tx_shift_reg   : std_logic_vector(9 downto 0) := (others => '1');
    
    type cmd_array_t is array (0 to 15) of std_logic_vector(7 downto 0);
    constant CMD_MODE : cmd_array_t := (
        X"24", X"24",
        X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", 
        X"00", X"00", X"00", X"00", X"00", X"00"
    );
    
    constant CMD_ADVERTISING : cmd_array_t := (
        X"41", X"34", X"0D",
        X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", 
        X"00", X"00", X"00", X"00", X"00"
    );
    
    constant CMD_REBOOT : cmd_array_t := (
        X"52", X"2C", X"31", X"0D",
        X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", 
        X"00", X"00", X"00", X"00"
    );
    
begin
    uart_tx_process: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ble_tx <= '1';
                bit_counter <= 0;
                bit_timer <= 0;
                uart_tx_ready <= '1';
                tx_shift_reg <= (others => '1');
            else
                if uart_tx_valid = '1' and uart_tx_ready = '1' then
                    uart_tx_ready <= '0';
                    tx_shift_reg <= '1' & uart_tx_data & '0';
                    bit_counter <= 0;
                    bit_timer <= 0;
                elsif bit_counter < 10 and uart_tx_ready = '0' then
                    if bit_timer = CLK_FREQ / 115200 - 1 then
                        ble_tx <= tx_shift_reg(0);
                        tx_shift_reg <= '1' & tx_shift_reg(9 downto 1);
                        bit_timer <= 0;
                        bit_counter <= bit_counter + 1;
                    else
                        bit_timer <= bit_timer + 1;
                    end if;
                elsif bit_counter = 10 then
                    uart_tx_ready <= '1';
                    bit_counter <= 0;
                else
                    ble_tx <= '1';
                end if;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            btn_reset_prev <= btn_reset;
            btn_cmd_prev <= btn_cmd;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            uart_tx_valid <= '0';
            
            if rst = '1' then
                state <= STATE_RESET;
                counter <= 0;
                cmd_sequence <= 0;
                ble_reset <= '0';
                ble_rts <= '1';
                led_status <= "00";
            else
                if counter /= CLK_FREQ * 5 then
                    counter <= counter + 1;
                end if;
                
                if btn_reset = '1' and btn_reset_prev = '0' then
                    state <= STATE_RESET;
                    counter <= 0;
                end if;
                
                if btn_cmd = '1' and btn_cmd_prev = '0' then
                    state <= STATE_CMD_ENTRY;
                    counter <= 0;
                    cmd_sequence <= 0;
                end if;
                
                case state is
                    when STATE_RESET =>
                        ble_reset <= '0';
                        ble_rts <= '1';
                        led_status <= "01";
                        
                        if counter >= CLK_FREQ / 10 then
                            state <= STATE_WAIT_RESET;
                            counter <= 0;
                        end if;
                    
                    when STATE_WAIT_RESET =>
                        ble_reset <= '1';
                        
                        if counter >= CLK_FREQ then
                            state <= STATE_NORMAL;
                            counter <= 0;
                        end if;
                    
                    when STATE_NORMAL =>
                        ble_reset <= '1';
                        ble_rts <= '0';
                        led_status <= "11";
                    
                    when STATE_CMD_ENTRY =>
                        led_status <= "10";
                        
                        if cmd_sequence < 2 then
                            if uart_tx_ready = '1' and uart_tx_valid = '0' then
                                uart_tx_data <= CMD_MODE(cmd_sequence);
                                uart_tx_valid <= '1';
                                cmd_sequence <= cmd_sequence + 1;
                                counter <= 0;
                            end if;
                        elsif counter >= CLK_FREQ / 2 then
                            state <= STATE_CMD_SEND_DISC;
                            cmd_sequence <= 0;
                            counter <= 0;
                        end if;
                    
                    when STATE_CMD_SEND_DISC =>
                        led_status <= "10";
                        
                        if cmd_sequence < 3 then
                            if uart_tx_ready = '1' and uart_tx_valid = '0' then
                                uart_tx_data <= CMD_ADVERTISING(cmd_sequence);
                                uart_tx_valid <= '1';
                                cmd_sequence <= cmd_sequence + 1;
                                counter <= 0;
                            end if;
                        elsif counter >= CLK_FREQ / 2 then
                            state <= STATE_CMD_SEND_REBOOT;
                            cmd_sequence <= 0;
                            counter <= 0;
                        end if;
                    
                    when STATE_CMD_SEND_REBOOT =>
                        led_status <= "10";
                        
                        if cmd_sequence < 4 then
                            if uart_tx_ready = '1' and uart_tx_valid = '0' then
                                uart_tx_data <= CMD_REBOOT(cmd_sequence);
                                uart_tx_valid <= '1';
                                cmd_sequence <= cmd_sequence + 1;
                                counter <= 0;
                            end if;
                        elsif counter >= CLK_FREQ then
                            state <= STATE_RESET;
                            counter <= 0;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
end ble_ctrl_behavior;
