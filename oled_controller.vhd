library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity oled_controller is
    Port (
        clk_i      : in  std_logic;
        rst_i      : in  std_logic;
        db_value_i : in  std_logic_vector(7 downto 0);
        update_i   : in  std_logic;
        sdin_o     : out std_logic;
        sclk_o     : out std_logic;
        dc_o       : out std_logic;
        res_o      : out std_logic;
        vbat_o     : out std_logic;
        vdd_o      : out std_logic;
        busy_o     : out std_logic
    );
end oled_controller;

architecture oled_behavior of oled_controller is
    constant OLED_WIDTH  : integer := 128;
    constant OLED_HEIGHT : integer := 32;
    constant SPI_CLK_DIV : integer := 25;
    
    signal spi_clk_counter : integer range 0 to SPI_CLK_DIV-1 := 0;
    signal spi_clk         : std_logic := '0';
    signal spi_data        : std_logic_vector(7 downto 0) := (others => '0');
    signal spi_busy        : std_logic := '0';
    signal spi_start       : std_logic := '0';
    signal spi_bit_count   : integer range 0 to 7 := 0;
    signal spi_done        : std_logic := '0';
    
    signal oled_init_done  : std_logic := '0';
    signal oled_reset      : std_logic := '0';
    signal oled_vbat       : std_logic := '0';
    signal oled_vdd        : std_logic := '0';
    signal oled_dc         : std_logic := '0';
    signal oled_data       : std_logic := '0';
    
    signal init_needs_dc   : std_logic := '0';
    signal init_dc_value   : std_logic := '0';
    signal display_needs_dc : std_logic := '0';
    signal display_dc_value : std_logic := '0';

    signal init_needs_spi_data   : std_logic := '0';
    signal init_spi_data         : std_logic_vector(7 downto 0) := (others => '0');
    signal display_needs_spi_data : std_logic := '0';
    signal display_spi_data       : std_logic_vector(7 downto 0) := (others => '0');
    
    signal init_needs_spi_start   : std_logic := '0';
    signal display_needs_spi_start : std_logic := '0';
    
    signal db_value_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal db_value_bcd    : std_logic_vector(11 downto 0) := (others => '0');
    
    type font_array is array(0 to 9) of std_logic_vector(39 downto 0);
    constant FONT : font_array := (
        "0111110100010100010100010111110000000000", 
        "0000000000100001111100000000000000000000",
        "0100110101010101010101011001000000000000",
        "0100010101010101010101011011100000000000",
        "0001110000100000111110000100000000000000",
        "1010110101010101010101010110100000000000",
        "0011110101010101010101001010000000000000",
        "1000000100000010000010111110000000000000",
        "0110110101010101010101011011000000000000",
        "0001000101010101010101011111000000000000"
    );
    
    type display_buffer_type is array(0 to 3) of std_logic_vector(127 downto 0);
    signal display_buffer : display_buffer_type := (others => (others => '0'));
    
    type main_state_type is (INIT, IDLE, PREPARE_DISPLAY, WAIT_SPI, UPDATE_DISPLAY, WAIT_FRAME);
    signal main_state : main_state_type := INIT;
    
    type init_state_type is (
        RESET_START, RESET_WAIT, VDD_ON, WAIT_VDD, RESET_CLEAR, WAIT_RESET,
        SEND_COMMANDS, VBAT_ON, WAIT_VBAT, DISPLAY_ON, INIT_DONE
    );
    signal init_state : init_state_type := RESET_START;
    
    type display_state_type is (
        SET_POSITION, SEND_PAGE_CMD, SEND_COL_LOW_CMD, SEND_COL_HIGH_CMD, SEND_DATA, NEXT_PAGE, DISPLAY_DONE
    );
    signal display_state : display_state_type := SET_POSITION;
    
    type cmd_array is array(0 to 23) of std_logic_vector(7 downto 0);
    constant INIT_COMMANDS : cmd_array := (
        x"AE",
        x"D5",
        x"80",
        x"A8",
        x"1F",
        x"D3",
        x"00",
        x"40",
        x"8D",
        x"14",
        x"20",
        x"00",
        x"A1",
        x"C8",
        x"DA",
        x"02",
        x"81",
        x"CF",
        x"D9",
        x"F1",
        x"DB",
        x"40",
        x"A4",
        x"AF"
    );
    
    signal cmd_index : integer range 0 to INIT_COMMANDS'length-1 := 0;
    signal page_index : integer range 0 to 3 := 0;
    signal col_index : integer range 0 to 127 := 0;
    
    constant RESET_DELAY : integer := 200000;
    constant VDD_DELAY   : integer := 500000;
    constant VBAT_DELAY  : integer := 12500000;
    constant FRAME_DELAY : integer := 1250000;
    
    signal init_delay_counter : integer range 0 to VBAT_DELAY := 0;
    signal frame_delay_counter : integer range 0 to FRAME_DELAY := 0;
    
    function to_bcd(bin : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable i : integer range 0 to 7;
        variable bcd : unsigned(11 downto 0) := (others => '0');
        variable bin_int : unsigned(7 downto 0);
    begin
        bin_int := unsigned(bin);
        
        for i in 0 to 7 loop
            if bcd(3 downto 0) > 4 then
                bcd(3 downto 0) := bcd(3 downto 0) + 3;
            end if;
            if bcd(7 downto 4) > 4 then
                bcd(7 downto 4) := bcd(7 downto 4) + 3;
            end if;
            if bcd(11 downto 8) > 4 then
                bcd(11 downto 8) := bcd(11 downto 8) + 3;
            end if;
            
            bcd := bcd(10 downto 0) & bin_int(7);
            bin_int := bin_int(6 downto 0) & '0';
        end loop;
        
        return std_logic_vector(bcd);
    end function;
    
    procedure create_db_display(
        signal db_bcd : in std_logic_vector(11 downto 0);
        signal display_buf : out display_buffer_type
    ) is
        variable hundreds : integer range 0 to 9;
        variable tens : integer range 0 to 9;
        variable ones : integer range 0 to 9;
        variable font_line : std_logic_vector(39 downto 0);
        variable buf_temp : display_buffer_type;
    begin
        buf_temp := (others => (others => '0'));
        
        hundreds := to_integer(unsigned(db_bcd(11 downto 8)));
        tens := to_integer(unsigned(db_bcd(7 downto 4)));
        ones := to_integer(unsigned(db_bcd(3 downto 0)));
        
        buf_temp(0)(127 downto 96) := x"FFFFFFFF";
        
        if hundreds > 0 then
            font_line := FONT(hundreds);
            buf_temp(1)(64+4 downto 64) := font_line(4 downto 0);
            buf_temp(2)(64+4 downto 64) := font_line(12 downto 8);
            buf_temp(3)(64+4 downto 64) := font_line(20 downto 16);
        end if;
        
        font_line := FONT(tens);
        buf_temp(1)(72+4 downto 72) := font_line(4 downto 0);
        buf_temp(2)(72+4 downto 72) := font_line(12 downto 8);
        buf_temp(3)(72+4 downto 72) := font_line(20 downto 16);
        
        font_line := FONT(ones);
        buf_temp(1)(80+4 downto 80) := font_line(4 downto 0);
        buf_temp(2)(80+4 downto 80) := font_line(12 downto 8);
        buf_temp(3)(80+4 downto 80) := font_line(20 downto 16);
        
        buf_temp(1)(88+8 downto 88) := "100010010";
        buf_temp(2)(88+8 downto 88) := "100010010";
        buf_temp(3)(88+8 downto 88) := "011101110";
        
        display_buf <= buf_temp;
    end procedure;

begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if spi_clk_counter = SPI_CLK_DIV-1 then
                spi_clk_counter <= 0;
                spi_clk <= not spi_clk;
            else
                spi_clk_counter <= spi_clk_counter + 1;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                spi_busy <= '0';
                spi_bit_count <= 0;
                spi_done <= '0';
                oled_data <= '0';
            else
                spi_done <= '0';
                
                if spi_start = '1' and spi_busy = '0' then
                    spi_busy <= '1';
                    spi_bit_count <= 7;
                    oled_data <= spi_data(7);
                elsif spi_busy = '1' and spi_clk = '0' and spi_clk_counter = SPI_CLK_DIV-1 then
                    if spi_bit_count = 0 then
                        spi_busy <= '0';
                        spi_done <= '1';
                    else
                        spi_bit_count <= spi_bit_count - 1;
                        oled_data <= spi_data(spi_bit_count - 1);
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                oled_dc <= '0';
            else
                if init_needs_dc = '1' then
                    oled_dc <= init_dc_value;
                elsif display_needs_dc = '1' then
                    oled_dc <= display_dc_value;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                spi_data <= (others => '0');
            else
                if init_needs_spi_data = '1' then
                    spi_data <= init_spi_data;
                elsif display_needs_spi_data = '1' then
                    spi_data <= display_spi_data;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                spi_start <= '0';
            else
                if spi_done = '1' then
                    spi_start <= '0';
                elsif init_needs_spi_start = '1' then
                    spi_start <= '1';
                elsif display_needs_spi_start = '1' then
                    spi_start <= '1';
                end if;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                main_state <= INIT;
                db_value_reg <= (others => '0');
                db_value_bcd <= (others => '0');
                busy_o <= '1';
                frame_delay_counter <= 0;
            else
                case main_state is
                    when INIT =>
                        busy_o <= '1';
                        if oled_init_done = '1' then
                            main_state <= IDLE;
                            busy_o <= '0';
                        end if;
                        
                    when IDLE =>
                        if update_i = '1' then
                            db_value_reg <= db_value_i;
                            main_state <= PREPARE_DISPLAY;
                            busy_o <= '1';
                        end if;
                        
                    when PREPARE_DISPLAY =>
                        db_value_bcd <= to_bcd(db_value_reg);
                        create_db_display(db_value_bcd, display_buffer);
                        main_state <= UPDATE_DISPLAY;
                        
                    when UPDATE_DISPLAY =>
                        if display_state = DISPLAY_DONE then
                            main_state <= WAIT_FRAME;
                            frame_delay_counter <= 0;
                        end if;
                        
                    when WAIT_FRAME =>
                        if frame_delay_counter >= FRAME_DELAY then
                            main_state <= IDLE;
                            busy_o <= '0';
                        else
                            frame_delay_counter <= frame_delay_counter + 1;
                        end if;
                        
                    when WAIT_SPI =>
                        if spi_busy = '0' then
                            main_state <= UPDATE_DISPLAY;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                init_state <= RESET_START;
                oled_init_done <= '0';
                oled_reset <= '0';
                oled_vdd <= '0';
                oled_vbat <= '0';
                cmd_index <= 0;
                init_delay_counter <= 0;
                init_needs_dc <= '0';
                init_dc_value <= '0';
                init_needs_spi_data <= '0';
                init_spi_data <= (others => '0');
                init_needs_spi_start <= '0';
            else
                case init_state is
                    when RESET_START =>
                        oled_reset <= '0';
                        oled_vdd <= '0';
                        oled_vbat <= '0';
                        init_delay_counter <= 0;
                        init_state <= RESET_WAIT;
                        init_needs_dc <= '0';
                        init_needs_spi_data <= '0';
                        init_needs_spi_start <= '0';
                        
                    when RESET_WAIT =>
                        if init_delay_counter >= RESET_DELAY then
                            init_state <= VDD_ON;
                            init_delay_counter <= 0;
                        else
                            init_delay_counter <= init_delay_counter + 1;
                        end if;
                        
                    when VDD_ON =>
                        oled_vdd <= '1';
                        init_state <= WAIT_VDD;
                        init_delay_counter <= 0;
                        
                    when WAIT_VDD =>
                        if init_delay_counter >= VDD_DELAY then
                            init_state <= RESET_CLEAR;
                            init_delay_counter <= 0;
                        else
                            init_delay_counter <= init_delay_counter + 1;
                        end if;
                        
                    when RESET_CLEAR =>
                        oled_reset <= '1';
                        init_state <= WAIT_RESET;
                        init_delay_counter <= 0;
                        
                    when WAIT_RESET =>
                        if init_delay_counter >= RESET_DELAY then
                            init_state <= SEND_COMMANDS;
                            cmd_index <= 0;
                        else
                            init_delay_counter <= init_delay_counter + 1;
                        end if;
                        
                    when SEND_COMMANDS =>
                        if spi_busy = '0' and spi_start = '0' then
                            if cmd_index < INIT_COMMANDS'length then
                                init_spi_data <= INIT_COMMANDS(cmd_index);
                                init_needs_spi_data <= '1';
                                init_needs_spi_start <= '1';
                                init_needs_dc <= '1';
                                init_dc_value <= '0';
                                cmd_index <= cmd_index + 1;
                            else
                                init_state <= VBAT_ON;
                                init_needs_dc <= '0';
                                init_needs_spi_data <= '0';
                                init_needs_spi_start <= '0';
                            end if;
                        elsif spi_done = '1' then
                            init_needs_spi_start <= '0';
                        end if;
                        
                    when VBAT_ON =>
                        oled_vbat <= '1';
                        init_state <= WAIT_VBAT;
                        init_delay_counter <= 0;
                        
                    when WAIT_VBAT =>
                        if init_delay_counter >= VBAT_DELAY then
                            init_state <= DISPLAY_ON;
                        else
                            init_delay_counter <= init_delay_counter + 1;
                        end if;
                        
                    when DISPLAY_ON =>
                        if spi_busy = '0' and spi_start = '0' then
                            init_spi_data <= x"AF";
                            init_needs_spi_data <= '1';
                            init_needs_spi_start <= '1';
                            init_needs_dc <= '1';
                            init_dc_value <= '0';
                            init_state <= INIT_DONE;
                        elsif spi_done = '1' then
                            init_needs_spi_start <= '0';
                        end if;
                        
                    when INIT_DONE =>
                        oled_init_done <= '1';
                        init_needs_dc <= '0';
                        init_needs_spi_data <= '0';
                end case;
            end if;
        end if;
    end process;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' or main_state = IDLE then
                display_state <= SET_POSITION;
                page_index <= 0;
                col_index <= 0;
                display_needs_dc <= '0';
                display_dc_value <= '0';
                display_needs_spi_data <= '0';
                display_spi_data <= (others => '0');
                display_needs_spi_start <= '0';
            elsif main_state = UPDATE_DISPLAY then
                case display_state is
                    when SET_POSITION =>
                        if spi_busy = '0' and spi_start = '0' then
                            display_spi_data <= x"B0" or std_logic_vector(to_unsigned(page_index, 8));
                            display_needs_spi_data <= '1';
                            display_needs_spi_start <= '1';
                            display_needs_dc <= '1';
                            display_dc_value <= '0';
                            display_state <= SEND_PAGE_CMD;
                        end if;
                        
                    when SEND_PAGE_CMD =>
                        if spi_done = '1' then
                            display_needs_spi_start <= '0';
                            display_state <= SEND_COL_LOW_CMD;
                        end if;
                        
                    when SEND_COL_LOW_CMD =>
                        if spi_busy = '0' and spi_start = '0' then
                            display_spi_data <= x"00";
                            display_needs_spi_data <= '1';
                            display_needs_spi_start <= '1';
                            display_needs_dc <= '1';
                            display_dc_value <= '0';
                            display_state <= SEND_COL_HIGH_CMD;
                        elsif spi_done = '1' then
                            display_needs_spi_start <= '0';
                        end if;
                        
                    when SEND_COL_HIGH_CMD =>
                        if spi_busy = '0' and spi_start = '0' then
                            display_spi_data <= x"10";
                            display_needs_spi_data <= '1';
                            display_needs_spi_start <= '1';
                            display_needs_dc <= '1';
                            display_dc_value <= '0';
                            display_state <= SEND_DATA;
                            col_index <= 0;
                        elsif spi_done = '1' then
                            display_needs_spi_start <= '0';
                        end if;
                    
                    when SEND_DATA =>
                        if spi_busy = '0' and spi_start = '0' then
                            if col_index < OLED_WIDTH then
                                display_spi_data <= display_buffer(page_index)(col_index) & 
                                               display_buffer(page_index)(col_index+1) & 
                                               display_buffer(page_index)(col_index+2) & 
                                               display_buffer(page_index)(col_index+3) & 
                                               display_buffer(page_index)(col_index+4) & 
                                               display_buffer(page_index)(col_index+5) & 
                                               display_buffer(page_index)(col_index+6) & 
                                               display_buffer(page_index)(col_index+7);
                                display_needs_spi_data <= '1';
                                display_needs_spi_start <= '1';
                                display_needs_dc <= '1';
                                display_dc_value <= '1';
                                col_index <= col_index + 8;
                            else
                                display_state <= NEXT_PAGE;
                            end if;
                        elsif spi_done = '1' then
                            display_needs_spi_start <= '0';
                        end if;
                    
                    when NEXT_PAGE =>
                        if page_index < 3 then
                            page_index <= page_index + 1;
                            display_state <= SET_POSITION;
                        else
                            display_state <= DISPLAY_DONE;
                            display_needs_dc <= '0';
                            display_needs_spi_data <= '0';
                            display_needs_spi_start <= '0';
                        end if;
                    
                    when DISPLAY_DONE =>
                        null;
                end case;
            end if;
        end if;
    end process;
    
    sdin_o <= oled_data;
    sclk_o <= spi_clk;
    dc_o <= oled_dc;
    res_o <= oled_reset;
    vbat_o <= oled_vbat;
    vdd_o <= oled_vdd;
    
end oled_behavior;