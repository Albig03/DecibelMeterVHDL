library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity bluetooth_decibel_top_tb is
end bluetooth_decibel_top_tb;

architecture tb_behavior of bluetooth_decibel_top_tb is
    component bluetooth_decibel_top
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
    end component;
    
    constant CLK_PERIOD : time := 8 ns;
    constant BIT_PERIOD : time := 8.68 us;
    
    constant START_MARKER : std_logic_vector(7 downto 0) := x"AA";
    constant END_MARKER   : std_logic_vector(7 downto 0) := x"55";
    
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal btn_ble_reset : std_logic := '0';
    signal btn_ble_cmd   : std_logic := '0';
    signal ble_rx        : std_logic := '1';
    
    signal ble_tx        : std_logic;
    signal ble_rts       : std_logic;
    signal ble_reset     : std_logic;
    signal ssd_seg_a     : std_logic;
    signal ssd_seg_b     : std_logic;
    signal ssd_seg_c     : std_logic;
    signal ssd_seg_d     : std_logic;
    signal ssd_seg_e     : std_logic;
    signal ssd_seg_f     : std_logic;
    signal ssd_seg_g     : std_logic;
    signal ssd_digit_sel : std_logic;
    signal leds          : std_logic_vector(3 downto 0);
    
    signal send_byte     : std_logic := '0';
    signal byte_to_send  : std_logic_vector(7 downto 0) := (others => '0');
    
    signal current_segments : std_logic_vector(6 downto 0);
    signal displayed_digit  : integer := 0;
    
    procedure uart_send_byte (
        signal tx_line : out std_logic;
        constant data  : in  std_logic_vector(7 downto 0)
    ) is
    begin
        tx_line <= '0';
        wait for BIT_PERIOD;
        
        for i in 0 to 7 loop
            tx_line <= data(i);
            wait for BIT_PERIOD;
        end loop;
        
        tx_line <= '1';
        wait for BIT_PERIOD;
    end procedure;
    
    procedure send_decibel_packet (
        signal tx_line : out std_logic;
        constant value : in integer
    ) is
        variable data_byte : std_logic_vector(7 downto 0);
    begin
        data_byte := std_logic_vector(to_unsigned(value, 8));
        
        uart_send_byte(tx_line, START_MARKER);
        wait for BIT_PERIOD;
        
        uart_send_byte(tx_line, data_byte);
        wait for BIT_PERIOD;
        
        uart_send_byte(tx_line, END_MARKER);
    end procedure;
    
    function segments_to_digit(segments : std_logic_vector(6 downto 0)) return character is
    begin
        case segments is
            when "0111111" => return '0';
            when "0000110" => return '1';
            when "1011011" => return '2';
            when "1001111" => return '3';
            when "1100110" => return '4';
            when "1101101" => return '5';
            when "1111101" => return '6';
            when "0000111" => return '7';
            when "1111111" => return '8';
            when "1101111" => return '9';
            when "1000000" => return '-';
            when others => return '?';
        end case;
    end function;
    
begin
    uut: bluetooth_decibel_top
    port map (
        clk => clk,
        rst => rst,
        btn_ble_reset => btn_ble_reset,
        btn_ble_cmd => btn_ble_cmd,
        ble_rx => ble_rx,
        ble_tx => ble_tx,
        ble_rts => ble_rts,
        ble_reset => ble_reset,
        ssd_seg_a => ssd_seg_a,
        ssd_seg_b => ssd_seg_b,
        ssd_seg_c => ssd_seg_c,
        ssd_seg_d => ssd_seg_d,
        ssd_seg_e => ssd_seg_e,
        ssd_seg_f => ssd_seg_f,
        ssd_seg_g => ssd_seg_g,
        ssd_digit_sel => ssd_digit_sel,
        leds => leds
    );
    
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    process
    begin
        wait until send_byte = '1';
        uart_send_byte(ble_rx, byte_to_send);
        wait until send_byte = '0';
    end process;
    
    current_segments <= ssd_seg_g & ssd_seg_f & ssd_seg_e & ssd_seg_d & 
                        ssd_seg_c & ssd_seg_b & ssd_seg_a;
    
    process
    begin
        wait for 10 * CLK_PERIOD;
        
        while true loop
            if ssd_digit_sel'event then
                if ssd_digit_sel = '1' then
                    report "Tens digit displaying: " & character'image(segments_to_digit(current_segments));
                else
                    report "Ones digit displaying: " & character'image(segments_to_digit(current_segments));
                end if;
            end if;
            
            wait for CLK_PERIOD;
        end loop;
    end process;
    
    process
    begin
        wait for 100 ns;
        
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        
        wait for 10 ms;
        
        report "Test Case 1: Sending decibel value 42";
        send_decibel_packet(ble_rx, 42);
        
        wait for 50 ms;
        
        report "Test Case 2: Sending decibel value 85";
        send_decibel_packet(ble_rx, 85);
        
        wait for 50 ms;
        
        report "Test Case 3: Sending decibel value 120 (should limit to 99)";
        send_decibel_packet(ble_rx, 120);
        
        wait for 50 ms;
        
        report "Test Case 4: Sending incomplete packet (missing end marker)";
        byte_to_send <= START_MARKER;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= x"37";
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        wait for 50 ms;
        
        report "Test Case 5: Sending valid packet after invalid one";
        send_decibel_packet(ble_rx, 23);
        
        wait for 50 ms;
        
        report "Test Case 6: Testing BLE reset button";
        btn_ble_reset <= '1';
        wait for 100 ns;
        btn_ble_reset <= '0';
        wait for 10 ms;
        
        send_decibel_packet(ble_rx, 77);
        
        wait for 50 ms;
        
        report "Test Case 7: Testing command mode button";
        btn_ble_cmd <= '1';
        wait for 100 ns;
        btn_ble_cmd <= '0';
        wait for 10 ms;
        
        send_decibel_packet(ble_rx, 63);
        
        wait for 50 ms;
        
        report "Test Case 8: Testing inactivity timeout (waiting for display to go inactive)";
        wait for 5.5 sec;
        
        report "Test Case 8 continued: Sending a packet after timeout";
        send_decibel_packet(ble_rx, 50);
        
        wait for 50 ms;
        
        report "Simulation completed successfully" severity note;
        wait;
    end process;
    
    process
    begin
        wait for 100 ns;
        
        loop
            if leds'event then
                report "LED Status: " & 
                      "LED0=" & std_logic'image(leds(0)) & " (IDLE state), " &
                      "LED1=" & std_logic'image(leds(1)) & " (GOT_START state), " &
                      "LED2=" & std_logic'image(leds(2)) & " (BLE status 0), " &
                      "LED3=" & std_logic'image(leds(3)) & " (BLE status 1)";
            end if;
            
            if ble_reset'event then
                report "BLE Reset pin changed to: " & std_logic'image(ble_reset);
            end if;
            
            if now > 6 sec then
                exit;
            end if;
            
            wait for 10 us;
        end loop;
        
        wait;
    end process;

end tb_behavior;
