library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_RX_TX_LIFO_TOP is
    generic(
        clk_per_bit     : integer := 1085;
        size            : integer := 8;
        debounce_cycles : integer := 1250000 -- 10 ms at 125 MHz
    );
    Port (
        clk       : in  std_logic;
        btn_read  : in  std_logic;
        btn_clear : in  std_logic;
        rx_serial : in  std_logic;
        tx_serial : out std_logic;
        full      : out std_logic;
        empty     : out std_logic
    );
end UART_RX_TX_LIFO_TOP;

architecture Behavioral of UART_RX_TX_LIFO_TOP is

    component UART_RX
        generic ( clk_per_bit : integer );
        Port (
            in_clk       : in  std_logic;
            in_rx_serial : in  std_logic;
            out_rx_valid : out std_logic;
            out_data     : out std_logic_vector(7 downto 0)
        );
    end component;

    component LIFO
        generic ( size : integer );
        Port (
            write    : in  std_logic;
            read     : in  std_logic;
            clear    : in  std_logic;
            clk      : in  std_logic;
            in_word  : in  std_logic_vector(7 downto 0);
            out_word : out std_logic_vector(7 downto 0);
            full     : out std_logic;
            empty    : out std_logic
        );
    end component;

    component UART_TX
        generic ( clk_per_bit : integer );
        Port (
            in_clk        : in  std_logic;
            in_tx_start   : in  std_logic;
            in_data       : in  std_logic_vector(7 downto 0);
            out_tx_serial : out std_logic;
            out_tx_active : out std_logic;
            out_tx_done   : out std_logic
        );
    end component;

    -- Data & status signals
    signal rx_valid    : std_logic;
    signal rx_data_in  : std_logic_vector(7 downto 0);
    signal tx_data_out : std_logic_vector(7 downto 0);
    signal empty_int   : std_logic;
    signal tx_active   : std_logic;

    -- 2-FF input synchronizers for asynchronous pushbuttons
    signal btn_read_sync  : std_logic_vector(1 downto 0) := (others => '0');
    signal btn_clear_sync : std_logic_vector(1 downto 0) := (others => '0');

    -- Debounce logic for btn_read
    signal debounce_cnt  : integer range 0 to debounce_cycles := 0;
    signal btn_debounced : std_logic := '0';
    signal btn_read_r    : std_logic := '0';

    signal read_pulse   : std_logic := '0';
    signal tx_start_reg : std_logic := '0';

begin

    -- Synchronize mechanical pushbuttons to system clock
    p_btn_sync : process(clk)
    begin
        if rising_edge(clk) then
            btn_read_sync  <= btn_read_sync(0) & btn_read;
            btn_clear_sync <= btn_clear_sync(0) & btn_clear;
        end if;
    end process p_btn_sync;

    -- Debounce btn_read and generate a single-cycle read pulse gated by TX availability
    p_debounce_and_read : process(clk)
    begin
        if rising_edge(clk) then
            if btn_read_sync(1) /= btn_debounced then
                if debounce_cnt < debounce_cycles then
                    debounce_cnt <= debounce_cnt + 1;
                else
                    btn_debounced <= btn_read_sync(1);
                    debounce_cnt  <= 0;
                end if;
            else
                debounce_cnt <= 0;
            end if;

            btn_read_r   <= btn_debounced;
            read_pulse   <= btn_debounced and (not btn_read_r) and (not empty_int) and (not tx_active);
            tx_start_reg <= read_pulse;
        end if;
    end process p_debounce_and_read;

    UART_RX_component : UART_RX
        generic map ( clk_per_bit => clk_per_bit )
        port map (
            in_clk       => clk,
            in_rx_serial => rx_serial,
            out_rx_valid => rx_valid,
            out_data     => rx_data_in
        );

    LIFO_mem : LIFO
        generic map ( size => size )
        port map (
            write    => rx_valid,
            read     => read_pulse,
            clear    => btn_clear_sync(1),
            clk      => clk,
            in_word  => rx_data_in,
            out_word => tx_data_out,
            full     => full,
            empty    => empty_int
        );

    inst_UART_TX : UART_TX
        generic map ( clk_per_bit => clk_per_bit )
        port map (
            in_clk        => clk,
            in_tx_start   => tx_start_reg,
            in_data       => tx_data_out,
            out_tx_serial => tx_serial,
            out_tx_active => tx_active,
            out_tx_done   => open
        );

    empty <= empty_int;

end Behavioral;
