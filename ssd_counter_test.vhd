library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ssd_counter is
    Port ( 
        clk         : in  std_logic;
        rst         : in  std_logic;
        
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
end ssd_counter;

architecture ssd_counter_behavior of ssd_counter is
    constant CLK_FREQ_HZ : integer := 125000000;
    
    signal slow_counter  : unsigned(26 downto 0) := (others => '0');
    signal digit_update  : std_logic := '0';
    
    signal digit1        : unsigned(3 downto 0) := "0000";
    signal digit0        : unsigned(3 downto 0) := "0000";
    signal segment_data  : std_logic_vector(6 downto 0);
    
    signal digit_select  : std_logic := '0';
    signal digit_counter : unsigned(15 downto 0) := (others => '0');
    
    signal counter_value : unsigned(7 downto 0) := (others => '0');
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            slow_counter <= slow_counter + 1;
            
            digit_update <= '0';
            
            if slow_counter = CLK_FREQ_HZ - 1 then
                slow_counter <= (others => '0');
                digit_update <= '1';
                
                if counter_value = 99 then
                    counter_value <= (others => '0');
                else
                    counter_value <= counter_value + 1;
                end if;
                
                digit1 <= counter_value(7 downto 4);
                digit0 <= counter_value(3 downto 0);
            end if;
            
            if rst = '1' then
                slow_counter <= (others => '0');
                counter_value <= (others => '0');
                digit0 <= "0000";
                digit1 <= "0000";
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            digit_counter <= digit_counter + 1;
            
            if digit_counter = CLK_FREQ_HZ/480 - 1 then
                digit_counter <= (others => '0');
                digit_select <= not digit_select;
            end if;
            
            if rst = '1' then
                digit_counter <= (others => '0');
                digit_select <= '0';
            end if;
        end if;
    end process;
    
    process(digit_select, digit0, digit1)
        variable digit_to_display : unsigned(3 downto 0);
    begin
        if digit_select = '0' then
            digit_to_display := digit0;
        else
            digit_to_display := digit1;
        end if;
        
        case digit_to_display is
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
    
    leds(0) <= slow_counter(23);
    leds(1) <= digit_select;
    leds(2) <= digit_update;
    leds(3) <= rst;
    
end ssd_counter_behavior;