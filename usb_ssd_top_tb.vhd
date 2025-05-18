library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity usb_ssd_top_tb is
end usb_ssd_top_tb;

architecture testbench of usb_ssd_top_tb is
    component usb_ssd_top is
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
    end component;
    
    constant CLK_PERIOD : time := 8 ns;
    constant BIT_PERIOD : time := 104166.7 ns;
    
    signal clk_tb           : std_logic := '0';
    signal rst_tb           : std_logic := '1';
    signal uart_rx_tb       : std_logic := '1';
    signal uart_tx_tb       : std_logic;
    
    signal ssd_seg_a_tb     : std_logic;
    signal ssd_seg_b_tb     : std_logic;
    signal ssd_seg_c_tb     : std_logic;
    signal ssd_seg_d_tb     : std_logic;
    signal ssd_seg_e_tb     : std_logic;
    signal ssd_seg_f_tb     : std_logic;
    signal ssd_seg_g_tb     : std_logic;
    signal ssd_digit_sel_tb : std_logic;
    
    signal leds_tb          : std_logic_vector(3 downto 0);
    
    procedure uart_send_byte (
        constant data_in : in std_logic_vector(7 downto 0);
        signal uart_tx : out std_logic
    ) is
    begin
        uart_tx <= '0';
        wait for BIT_PERIOD;
        
        for i in 0 to 7 loop
            uart_tx <= data_in(i);
            wait for BIT_PERIOD;
        end loop;
        
        uart_tx <= '1';
        wait for BIT_PERIOD;
    end procedure;
    
    function segments_to_decimal(
        seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g : std_logic
    ) return integer is
        variable segments : std_logic_vector(6 downto 0);
    begin
        segments := seg_g & seg_f & seg_e & seg_d & seg_c & seg_b & seg_a;
        
        case segments is
            when "0111111" => return 0;
            when "0000110" => return 1;
            when "1011011" => return 2;
            when "1001111" => return 3;
            when "1100110" => return 4;
            when "1101101" => return 5;
            when "1111101" => return 6;
            when "0000111" => return 7;
            when "1111111" => return 8;
            when "1101111" => return 9;
            when others    => return -1;
        end case;
    end function;
    
begin
    dut: usb_ssd_top
    port map (
        clk           => clk_tb,
        rst           => rst_tb,
        uart_rx       => uart_rx_tb,
        uart_tx       => uart_tx_tb,
        ssd_seg_a     => ssd_seg_a_tb,
        ssd_seg_b     => ssd_seg_b_tb,
        ssd_seg_c     => ssd_seg_c_tb,
        ssd_seg_d     => ssd_seg_d_tb,
        ssd_seg_e     => ssd_seg_e_tb,
        ssd_seg_f     => ssd_seg_f_tb,
        ssd_seg_g     => ssd_seg_g_tb,
        ssd_digit_sel => ssd_digit_sel_tb,
        leds          => leds_tb
    );
    
    process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    process
    begin
        rst_tb <= '1';
        wait for 100 ns;
        rst_tb <= '0';
        wait for 100 ns;
        
        report "Sending UART data: 42";
        uart_send_byte(x"34", uart_rx_tb);
        wait for BIT_PERIOD * 2;
        uart_send_byte(x"32", uart_rx_tb);
        
        wait for 10 ms;
        
        report "Sending UART data: 75";
        uart_send_byte(x"37", uart_rx_tb);
        wait for BIT_PERIOD * 2;
        uart_send_byte(x"35", uart_rx_tb);
        
        wait for 10 ms;
        
        report "Sending UART data: A9 (A should be ignored)";
        uart_send_byte(x"41", uart_rx_tb);
        wait for BIT_PERIOD * 2;
        uart_send_byte(x"39", uart_rx_tb);
        
        wait for 10 ms;
        
        report "Sending UART data: 12XYZ (XYZ should be ignored)";
        uart_send_byte(x"31", uart_rx_tb);
        wait for BIT_PERIOD * 2;
        uart_send_byte(x"32", uart_rx_tb);
        wait for BIT_PERIOD * 2;
        uart_send_byte(x"58", uart_rx_tb);
        wait for BIT_PERIOD * 2;
        uart_send_byte(x"59", uart_rx_tb);
        wait for BIT_PERIOD * 2;
        uart_send_byte(x"5A", uart_rx_tb);
        
        wait for 10 ms;
        
        report "Waiting to observe test mode (automatic counting)";
        wait for 800 ms;
        
        report "Waiting for test mode to activate";
        wait for 5 sec;
        
        report "Observing test mode counting";
        wait for 5 sec;
        
        report "End of simulation";
        wait;
    end process;
    
    process
        variable current_digit0, current_digit1 : integer;
        variable digit_sel_prev : std_logic := '0';
    begin
        wait until rising_edge(clk_tb);
        
        if digit_sel_prev /= ssd_digit_sel_tb then
            digit_sel_prev := ssd_digit_sel_tb;
            
            if ssd_digit_sel_tb = '0' then
                current_digit0 := segments_to_decimal(
                    ssd_seg_a_tb, ssd_seg_b_tb, ssd_seg_c_tb, ssd_seg_d_tb,
                    ssd_seg_e_tb, ssd_seg_f_tb, ssd_seg_g_tb
                );
                if current_digit0 /= -1 then
                    report "Digit 0 displays: " & integer'image(current_digit0);
                end if;
            else
                current_digit1 := segments_to_decimal(
                    ssd_seg_a_tb, ssd_seg_b_tb, ssd_seg_c_tb, ssd_seg_d_tb,
                    ssd_seg_e_tb, ssd_seg_f_tb, ssd_seg_g_tb
                );
                if current_digit1 /= -1 then
                    report "Digit 1 displays: " & integer'image(current_digit1);
                end if;
            end if;
        end if;
    end process;
    
    process
    begin
        wait until rising_edge(clk_tb);
        
        if leds_tb(3) = '1' and leds_tb(3)'event then
            report "Test mode activated";
        end if;
        
        if leds_tb(2) = '1' and leds_tb(2)'event then
            report "UART RX activity detected";
        end if;
    end process;
    
end testbench;