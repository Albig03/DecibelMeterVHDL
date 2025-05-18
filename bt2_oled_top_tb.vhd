library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity bt2_oled_top_tb is
end bt2_oled_top_tb;

architecture behavior of bt2_oled_top_tb is
    component bt2_oled_top
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
    end component;
    
    constant CLK_PERIOD : time := 8 ns;
    constant BIT_PERIOD : time := 8.68 us;
    
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal leds         : std_logic_vector(3 downto 0);
    signal bt_rx        : std_logic := '1';
    signal bt_tx        : std_logic;
    signal bt_cts       : std_logic := '0';
    signal bt_rts       : std_logic;
    signal bt_reset     : std_logic;
    signal oled_sdin    : std_logic;
    signal oled_sclk    : std_logic;
    signal oled_dc      : std_logic;
    signal oled_res     : std_logic;
    signal oled_vbat    : std_logic;
    signal oled_vdd     : std_logic;
    
    signal send_byte    : std_logic := '0';
    signal byte_to_send : std_logic_vector(7 downto 0) := (others => '0');
    
    constant START_BYTE : std_logic_vector(7 downto 0) := x"02";
    constant END_BYTE   : std_logic_vector(7 downto 0) := x"03";
    
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

begin
    uut: bt2_oled_top
    port map (
        clk_i       => clk,
        rst_i       => rst,
        leds_o      => leds,
        bt_rx_i     => bt_rx,
        bt_tx_o     => bt_tx,
        bt_cts_i    => bt_cts,
        bt_rts_o    => bt_rts,
        bt_reset_o  => bt_reset,
        oled_sdin_o => oled_sdin,
        oled_sclk_o => oled_sclk,
        oled_dc_o   => oled_dc,
        oled_res_o  => oled_res,
        oled_vbat_o => oled_vbat,
        oled_vdd_o  => oled_vdd
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
        uart_send_byte(bt_rx, byte_to_send);
        wait until send_byte = '0';
    end process;
    
    process
    begin
        wait for 100 ns;
        
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        
        wait for 50 ms;
        
        byte_to_send <= START_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= x"A5";
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= END_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        wait for 10 ms;
        
        byte_to_send <= START_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= x"3C";
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= END_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        wait for 10 ms;
        
        byte_to_send <= START_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= x"FF";
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= x"AA";
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        wait for 10 ms;
        
        byte_to_send <= START_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= x"55";
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= END_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        wait for 10 ms;
        
        byte_to_send <= START_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        
        byte_to_send <= START_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= x"69";
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        byte_to_send <= END_BYTE;
        send_byte <= '1';
        wait for 10 ns;
        send_byte <= '0';
        wait for BIT_PERIOD * 12;
        
        wait for 20 ms;
        
        wait;
    end process;
    
    process
    begin
        wait for 100 ns;
        
        loop
            if leds'event then
                report "LED Status: " & 
                       "LED0=" & std_logic'image(leds(0)) & ", " &
                       "LED1=" & std_logic'image(leds(1)) & ", " &
                       "LED2=" & std_logic'image(leds(2)) & ", " &
                       "LED3=" & std_logic'image(leds(3));
            end if;
            
            wait for 1 us;
            
            if now > 150 ms then
                exit;
            end if;
        end loop;
        
        wait;
    end process;

end behavior;