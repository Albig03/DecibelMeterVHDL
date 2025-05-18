library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bt2_oled_top is
    Port (
        clk_i      : in  std_logic;
        rst_i      : in  std_logic;
        
        leds_o     : out std_logic_vector(3 downto 0);
        
        bt_rx_i    : in  std_logic;
        bt_tx_o    : out std_logic;
        bt_cts_i   : in  std_logic;
        bt_rts_o   : out std_logic;
        bt_reset_o : out std_logic;
        
        oled_sdin_o : out std_logic;
        oled_sclk_o : out std_logic;
        oled_dc_o   : out std_logic;
        oled_res_o  : out std_logic;
        oled_vbat_o : out std_logic;
        oled_vdd_o  : out std_logic
    );
end bt2_oled_top;

architecture bt2_oled_behavior of bt2_oled_top is
    constant CLK_FREQ   : integer := 125000000;
    constant BAUD_RATE  : integer := 115200;
    
    constant START_BYTE : std_logic_vector(7 downto 0) := x"AA"; 
    constant END_BYTE   : std_logic_vector(7 downto 0) := x"55"; 
    
    signal uart_rx_data  : std_logic_vector(7 downto 0);
    signal uart_rx_valid : std_logic;
    
    signal uart_tx_data  : std_logic_vector(7 downto 0);
    signal uart_tx_start : std_logic := '0';
    signal uart_tx_busy  : std_logic;
    
    type packet_state_type is (WAIT_START, WAIT_DATA, WAIT_END);
    signal packet_state : packet_state_type := WAIT_START;
    signal data_byte    : std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid   : std_logic := '0';
    signal data_update  : std_logic := '0';
    
    signal oled_busy    : std_logic;
    
    signal prev_data_valid : std_logic := '0';

begin
    uart_rx_inst : entity work.uart_receiver_bt2
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk_i      => clk_i,
            rst_i      => rst_i,
            rx_i       => bt_rx_i,
            rx_data_o  => uart_rx_data,
            rx_valid_o => uart_rx_valid
        );
    
    uart_tx_inst : entity work.uart_transmitter_bt2
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk_i      => clk_i,
            rst_i      => rst_i,
            tx_data_i  => uart_tx_data,
            tx_start_i => uart_tx_start,
            tx_busy_o  => uart_tx_busy,
            tx_o       => bt_tx_o
        );
    
    oled_controller_inst : entity work.oled_controller
        port map (
            clk_i      => clk_i,
            rst_i      => rst_i,
            db_value_i => data_byte,
            update_i   => data_update,
            sdin_o     => oled_sdin_o,
            sclk_o     => oled_sclk_o,
            dc_o       => oled_dc_o,
            res_o      => oled_res_o,
            vbat_o     => oled_vbat_o,
            vdd_o      => oled_vdd_o,
            busy_o     => oled_busy
        );
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                packet_state <= WAIT_START;
                data_byte <= (others => '0');
                data_valid <= '0';
            else
                data_valid <= '0';
                
                if uart_rx_valid = '1' then
                    case packet_state is
                        when WAIT_START =>
                            if uart_rx_data = START_BYTE then
                                packet_state <= WAIT_DATA;
                            end if;
                            
                        when WAIT_DATA =>
                            data_byte <= uart_rx_data;
                            packet_state <= WAIT_END;
                            
                        when WAIT_END =>
                            if uart_rx_data = END_BYTE then
                                data_valid <= '1';
                                packet_state <= WAIT_START;
                            else
                                packet_state <= WAIT_START;
                            end if;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                data_update <= '0';
                prev_data_valid <= '0';
            else
                data_update <= '0';
                
                if data_valid = '1' and prev_data_valid = '0' and oled_busy = '0' then
                    data_update <= '1';
                end if;
                
                prev_data_valid <= data_valid;
            end if;
        end if;
    end process;
    
    bt_reset_o <= '1';
    bt_rts_o <= '0';
    
    leds_o(0) <= '1' when packet_state = WAIT_START else '0';
    leds_o(1) <= '1' when packet_state = WAIT_DATA else '0';
    leds_o(2) <= '1' when packet_state = WAIT_END else '0';
    leds_o(3) <= data_valid;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                uart_tx_start <= '0';
                uart_tx_data <= (others => '0');
            else
                uart_tx_start <= '0';
                
                if data_valid = '1' and uart_tx_busy = '0' then
                    uart_tx_data <= data_byte;
                    uart_tx_start <= '1';
                end if;
            end if;
        end if;
    end process;
    
end bt2_oled_behavior;