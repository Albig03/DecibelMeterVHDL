library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ble_ssd_top is
    Port ( 
        clk         : in  std_logic;
        rst         : in  std_logic;
        
        btn_ble_reset : in std_logic;
        btn_ble_cmd   : in std_logic;
        
        ble_rx      : in  std_logic;
        ble_tx      : out std_logic;
        ble_rts     : out std_logic;
        ble_reset   : out std_logic;
        
        ssd_seg_a   : out std_logic;
        ssd_seg_b   : out std_logic;
        ssd_seg_c   : out std_logic;
        ssd_seg_d   : out std_logic;
        
        ssd_seg_e   : out std_logic;
        ssd_seg_f   : out std_logic;
        ssd_seg_g   : out std_logic;
        ssd_digit_sel : out std_logic;
        
        leds        : out std_logic_vector(3 downto 0)
    );
end ble_ssd_top;

architecture ble_ssd_behavior of ble_ssd_top is
    constant CLK_FREQ_HZ : integer := 125_000_000;
    constant BAUD_RATE   : integer := 115200;
    
    constant START_MARKER : std_logic_vector(7 downto 0) := x"AA";
    constant END_MARKER   : std_logic_vector(7 downto 0) := x"55";
    
    signal rx_data        : std_logic_vector(7 downto 0);
    signal rx_data_valid  : std_logic;
    
    signal ble_status     : std_logic_vector(1 downto 0);
    
    signal decibel_value  : unsigned(7 downto 0);
    signal decibel_valid  : std_logic;
    
    signal digit1         : unsigned(3 downto 0);
    signal digit0         : unsigned(3 downto 0);
    signal current_digit  : unsigned(3 downto 0);
    signal segment_data   : std_logic_vector(6 downto 0);
    
    signal digit_select   : std_logic := '0';
    signal digit_counter  : unsigned(23 downto 0) := (others => '0');
    
    signal display_active : std_logic := '0';
    signal inactive_counter : unsigned(27 downto 0) := (others => '0');
    constant INACTIVE_TIMEOUT : unsigned(27 downto 0) := to_unsigned(125_000_000 * 5, 28);
    
    type parse_state_t is (IDLE, GOT_START, GOT_DATA);
    signal parse_state    : parse_state_t := IDLE;

begin
    uart_rx_inst : entity work.uart_rx
    generic map (
        CLK_FREQ    => CLK_FREQ_HZ,
        BAUD_RATE   => BAUD_RATE
    )
    port map (
        clk         => clk,
        rst         => rst,
        rx          => ble_rx,
        data_out    => rx_data,
        data_valid  => rx_data_valid
    );
    
    ble_control_inst : entity work.ble_control
    generic map (
        CLK_FREQ    => CLK_FREQ_HZ
    )
    port map (
        clk         => clk,
        rst         => rst,
        ble_reset   => ble_reset,
        ble_rts     => ble_rts,
        ble_tx      => ble_tx,
        ble_rx      => ble_rx,
        btn_reset   => btn_ble_reset,
        btn_cmd     => btn_ble_cmd,
        led_status  => ble_status
    );
    
    bluetooth_parser : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                parse_state <= IDLE;
                decibel_valid <= '0';
            else
                decibel_valid <= '0';
                
                case parse_state is
                    when IDLE =>
                        if rx_data_valid = '1' and rx_data = START_MARKER then
                            parse_state <= GOT_START;
                        end if;
                        
                    when GOT_START =>
                        if rx_data_valid = '1' then
                            decibel_value <= unsigned(rx_data);
                            parse_state <= GOT_DATA;
                        end if;
                        
                    when GOT_DATA =>
                        if rx_data_valid = '1' then
                            if rx_data = END_MARKER then
                                decibel_valid <= '1';
                                parse_state <= IDLE;
                            else
                                parse_state <= IDLE;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    bcd_conversion : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                digit1 <= (others => '0');
                digit0 <= (others => '0');
            elsif decibel_valid = '1' then
                if decibel_value > 99 then
                    digit1 <= to_unsigned(9, 4);
                    digit0 <= to_unsigned(9, 4);
                else
                    digit1 <= resize(decibel_value / 10, 4);
                    digit0 <= resize(decibel_value mod 10, 4);
                end if;
            end if;
        end if;
    end process;
    
    activity_timeout_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                inactive_counter <= (others => '0');
                display_active <= '0';
            elsif decibel_valid = '1' then
                inactive_counter <= (others => '0');
                display_active <= '1';
            elsif display_active = '1' then
                if inactive_counter = INACTIVE_TIMEOUT then
                    display_active <= '0';
                else
                    inactive_counter <= inactive_counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    digit_multiplex : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                digit_counter <= (others => '0');
                digit_select <= '0';
            else
                digit_counter <= digit_counter + 1;
                
                if digit_counter = CLK_FREQ_HZ/100 then
                    digit_counter <= (others => '0');
                    digit_select <= not digit_select;
                end if;
            end if;
        end if;
    end process;
    
    current_digit <= 
        "0000" when display_active = '0' else
        digit1 when digit_select = '1' else
        digit0;
    
    with current_digit select
        segment_data <= "0111111" when "0000",
                        "0000110" when "0001",
                        "1011011" when "0010",
                        "1001111" when "0011",
                        "1100110" when "0100",
                        "1101101" when "0101",
                        "1111101" when "0110",
                        "0000111" when "0111",
                        "1111111" when "1000",
                        "1101111" when "1001",
                        "1000000" when others;

    ssd_seg_a <= segment_data(0);
    ssd_seg_b <= segment_data(1);
    ssd_seg_c <= segment_data(2);
    ssd_seg_d <= segment_data(3);
    ssd_seg_e <= segment_data(4);
    ssd_seg_f <= segment_data(5);
    ssd_seg_g <= segment_data(6);
    
    ssd_digit_sel <= digit_select;
    
    leds(0) <= '1' when parse_state = IDLE else '0';
    leds(1) <= '1' when parse_state = GOT_START else '0';
    leds(2) <= ble_status(0);
    leds(3) <= ble_status(1);
    
end ble_ssd_behavior;
