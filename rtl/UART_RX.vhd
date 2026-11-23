library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity UART_RX is
    generic(
        clk_per_bit : integer := 1085
    );
    Port (
        in_clk       : in  std_logic;
        in_rx_serial : in  std_logic;
        out_rx_valid : out std_logic;
        out_data     : out std_logic_vector(7 downto 0)
    );
end UART_RX;

architecture Behavioral of UART_RX is

    type states is (idle, start_check, receive, stop, flag_stable);

    signal state      : states := idle;
    signal next_state : states := idle;

    signal r_rx_data_r : std_logic := '1'; -- 2-FF input synchronizer stage 1
    signal r_rx_data   : std_logic := '1'; -- 2-FF input synchronizer stage 2

    signal count : integer range 0 to clk_per_bit - 1 := 0;
    signal index : integer range 0 to 7 := 0;

    signal out_data_temp : std_logic_vector(7 downto 0) := (others => '0');

begin

    p_sample : process(in_clk)
    begin
        if rising_edge(in_clk) then
            r_rx_data_r <= in_rx_serial;
            r_rx_data   <= r_rx_data_r;
        end if;
    end process p_sample;

    state_update : process(in_clk)
    begin
        if rising_edge(in_clk) then
            state <= next_state;
        end if;
    end process state_update;

    state_control : process(state, r_rx_data, index, count)
    begin
        case state is

            when idle =>
                if r_rx_data = '0' then
                    next_state <= start_check;
                else
                    next_state <= idle;
                end if;

            when start_check =>
                if count = (clk_per_bit - 1) / 2 then
                    if r_rx_data = '0' then
                        next_state <= receive;
                    else
                        next_state <= idle;
                    end if;
                else
                    next_state <= start_check;
                end if;

            when receive =>
                if count < clk_per_bit - 1 then
                    next_state <= receive;
                elsif index = 7 then
                    next_state <= stop;
                else
                    next_state <= receive;
                end if;

            when stop =>
                if count < clk_per_bit - 1 then
                    next_state <= stop;
                elsif r_rx_data = '1' then
                    next_state <= flag_stable;
                else
                    next_state <= idle; -- Framing error: ignore corrupt byte
                end if;

            when flag_stable =>
                next_state <= idle;

            when others =>
                next_state <= idle;
        end case;
    end process state_control;

    resources_control : process(in_clk)
    begin
        if rising_edge(in_clk) then
            case state is

                when idle =>
                    count        <= 0;
                    index        <= 0;
                    out_rx_valid <= '0';

                when start_check =>
                    if state = start_check and next_state = receive then
                        count <= 0;
                    else
                        count <= count + 1;
                    end if;

                when receive =>
                    if count < clk_per_bit - 1 then
                        count <= count + 1;
                    else
                        count                <= 0;
                        out_data_temp(index) <= r_rx_data;
                        if index = 7 then
                            index <= 0;
                        else
                            index <= index + 1;
                        end if;
                    end if;

                when stop =>
                    if count < clk_per_bit - 1 then
                        count <= count + 1;
                    else
                        count <= 0;
                    end if;

                when flag_stable =>
                    out_rx_valid <= '1';
                    out_data     <= out_data_temp;

                when others =>
                    null;
            end case;
        end if;
    end process resources_control;

end Behavioral;
