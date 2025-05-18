library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity usb_ssd_top is
    Port ( 
        clk         : in  std_logic;
        rst         : in  std_logic;
        
        uart_rx     : in  std_logic;
        uart_tx     : out std_logic;
        
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
end usb_ssd_top;

architecture usb_top_behavior of usb_ssd_top is
    constant CLK_FREQ_HZ : integer := 125_000_000;
    constant BAUD_RATE   : integer := 9600;
    
    signal rx_data        : std_logic_vector(7 downto 0);
    signal rx_data_valid  : std_logic;
    
    signal digit1         : unsigned(3 downto 0) := "0000";
    signal digit0         : unsigned(3 downto 0) := "0000";
    signal segment_data   : std_logic_vector(6 downto 0);
    
    signal digit_select   : std_logic := '0';
    signal digit_counter  : unsigned(16 downto 0) := (others => '0');
    
    type parse_state_t is (WAIT_FIRST, WAIT_SECOND);
    signal parse_state    : parse_state_t := WAIT_FIRST;
    
    signal rx_activity    : std_logic := '0';
    signal activity_counter : unsigned(27 downto 0) := (others => '0');
    signal test_mode      : std_logic := '0';
    signal test_counter   : unsigned(24 downto 0) := (others => '0');
    
    signal rx_byte_count  : unsigned(7 downto 0) := (others => '0');
    signal digit_update_occurred : std_logic := '0';
    
    function ascii_to_digit(ascii : std_logic_vector(7 downto 0)) return unsigned is
    begin
        if ascii >= x"30" and ascii <= x"39" then
            return unsigned(ascii(3 downto 0));
        else
            return "0000";
        end if;
    end function;

begin
    uart_rx_inst : entity work.uart_rx
    generic map (
        CLK_FREQ    => CLK_FREQ_HZ,
        BAUD_RATE   => BAUD_RATE
    )
    port map (
        clk         => clk,
        rst         => rst,
        rx          => uart_rx,
        data_out    => rx_data,
        data_valid  => rx_data_valid
    );
    
    uart_tx <= '1';
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                activity_counter <= (others => '0');
                test_mode <= '0';
                rx_byte_count <= (others => '0');
            elsif rx_data_valid = '1' then
                activity_counter <= (others => '0');
                test_mode <= '0';
                rx_byte_count <= rx_byte_count + 1;
            else
                if activity_counter = CLK_FREQ_HZ * 5 then
                    test_mode <= '1';
                else
                    activity_counter <= activity_counter + 1;
                end if;
            end if;
            
            if rx_data_valid = '1' then
                rx_activity <= '1';
            else
                rx_activity <= '0';
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            digit_update_occurred <= '0';
            
            if rst = '1' then
                parse_state <= WAIT_FIRST;
                digit1 <= "0000";
                digit0 <= "0000";
            elsif test_mode = '0' then
                if rx_data_valid = '1' then
                    case parse_state is
                        when WAIT_FIRST =>
                            if rx_data >= x"30" and rx_data <= x"39" then
                                digit1 <= ascii_to_digit(rx_data);
                                parse_state <= WAIT_SECOND;
                            end if;
                            
                        when WAIT_SECOND =>
                            if rx_data >= x"30" and rx_data <= x"39" then
                                digit0 <= ascii_to_digit(rx_data);
                                digit_update_occurred <= '1';
                                parse_state <= WAIT_FIRST;
                            else
                                parse_state <= WAIT_FIRST;
                            end if;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                test_counter <= (others => '0');
            else
                test_counter <= test_counter + 1;
                
                if test_mode = '1' then
                    if test_counter = CLK_FREQ_HZ - 1 then
                        test_counter <= (others => '0');
                        
                        if digit0 = "1001" then
                            digit0 <= "0000";
                            
                            if digit1 = "1001" then
                                digit1 <= "0000";
                            else
                                digit1 <= digit1 + 1;
                            end if;
                        else
                            digit0 <= digit0 + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                digit_counter <= (others => '0');
                digit_select <= '0';
            else
                digit_counter <= digit_counter + 1;
                
                if digit_counter = CLK_FREQ_HZ/1000 then
                    digit_counter <= (others => '0');
                    digit_select <= not digit_select;
                end if;
            end if;
        end if;
    end process;
    
    process(digit_select, digit0, digit1)
        variable current_digit : unsigned(3 downto 0);
    begin
        if digit_select = '0' then
            current_digit := digit0;
        else
            current_digit := digit1;
        end if;
        
        case current_digit is
            when "0000" => segment_data <= "0111111";
            when "0001" => segment_data <= "0000110";
            when "0010" => segment_data <= "1011011";
            when "0011" => segment_data <= "1001111";
            when "0100" => segment_data <= "1100110";
            when "0101" => segment_data <= "1101101";
            when "0110" => segment_data <= "1111101";
            when "0111" => segment_data <= "0000111";
            when "1000" => segment_data <= "1111111";
            when "1001" => segment_data <= "1101111";
            when others => segment_data <= "1000000";
        end case;
    end process;

    ssd_seg_a <= segment_data(0);
    ssd_seg_b <= segment_data(1);
    ssd_seg_c <= segment_data(2);
    ssd_seg_d <= segment_data(3);
    ssd_seg_e <= segment_data(4);
    ssd_seg_f <= segment_data(5);
    ssd_seg_g <= segment_data(6);
    
    ssd_digit_sel <= digit_select;
    
    leds(0) <= '1' when parse_state = WAIT_FIRST else '0';
    leds(1) <= uart_rx;
    leds(2) <= rx_activity;
    leds(3) <= test_mode;
    
end usb_top_behavior;
