library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity UART_TX is
    generic(
        clk_per_bit : integer := 1085
    );
    Port (
        in_clk        : in  std_logic;
        in_tx_start   : in  std_logic;
        in_data       : in  std_logic_vector(7 downto 0);
        out_tx_serial : out std_logic;
        out_tx_active : out std_logic;
        out_tx_done   : out std_logic
    );
end UART_TX;

architecture Behavioral of UART_TX is

    type states is (idle, start_bit, transmit, stop_bit, flag_done);

    signal state      : states := idle;
    signal next_state : states := idle;

    signal count      : integer range 0 to clk_per_bit - 1 := 0;
    signal index      : integer range 0 to 7 := 0;

    signal in_data_temp : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- State register process
    state_update : process(in_clk)
    begin
        if rising_edge(in_clk) then
            state <= next_state;
        end if;
    end process state_update;

    -- Next state logic
    state_control : process(state, in_tx_start, index, count)
    begin
        case state is

            when idle =>
                if in_tx_start = '1' then
                    next_state <= start_bit;
                else
                    next_state <= idle;
                end if;

            when start_bit =>
                if count = clk_per_bit - 1 then
                    next_state <= transmit;
                else
                    next_state <= start_bit;
                end if;

            when transmit =>
                if count < clk_per_bit - 1 then
                    next_state <= transmit;
                elsif index = 7 then
                    next_state <= stop_bit;
                else
                    next_state <= transmit;
                end if;

            when stop_bit =>
                if count < clk_per_bit - 1 then
                    next_state <= stop_bit;
                else
                    next_state <= flag_done;
                end if;

            when flag_done =>
                next_state <= idle;

            when others =>
                next_state <= idle;
        end case;
    end process state_control;

    -- Output and resource management process
    resources_control : process(in_clk)
    begin
        if rising_edge(in_clk) then
            case state is

                when idle =>
                    out_tx_serial <= '1'; -- UART line idles high
                    out_tx_active <= '0';
                    out_tx_done   <= '0';
                    count         <= 0;
                    index         <= 0;
                    if in_tx_start = '1' then
                        in_data_temp <= in_data; -- Latch input byte
                    end if;

                when start_bit =>
                    out_tx_serial <= '0'; -- Start bit is logic low ('0')
                    out_tx_active <= '1';
                    if count < clk_per_bit - 1 then
                        count <= count + 1;
                    else
                        count <= 0;
                    end if;

                when transmit =>
                    out_tx_serial <= in_data_temp(index); -- LSB first
                    out_tx_active <= '1';
                    if count < clk_per_bit - 1 then
                        count <= count + 1;
                    else
                        count <= 0;
                        if index = 7 then
                            index <= 0;
                        else
                            index <= index + 1;
                        end if;
                    end if;

                when stop_bit =>
                    out_tx_serial <= '1'; -- Stop bit is logic high ('1')
                    out_tx_active <= '1';
                    if count < clk_per_bit - 1 then
                        count <= count + 1;
                    else
                        count <= 0;
                    end if;

                when flag_done =>
                    out_tx_active <= '0';
                    out_tx_done   <= '1'; -- Pulsed '1' for one cycle upon completion

                when others =>
                    null;
            end case;
        end if;
    end process resources_control;

end Behavioral;