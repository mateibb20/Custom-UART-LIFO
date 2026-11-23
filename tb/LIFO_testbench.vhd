library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LIFO_testbench is
end LIFO_testbench;

architecture Behavioral of LIFO_testbench is

    component LIFO is
        generic (
            size : integer := 8
        );
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

    constant clk_period : time := 8 ns;

    signal ex_read, ex_write, ex_clear, ex_clk, ex_full, ex_empty : std_logic := '0';
    signal ex_in, ex_out : std_logic_vector(7 downto 0) := (others => '0');

begin

    mem : LIFO
        generic map(
            size => 8
        )
        port map(
            write    => ex_write,
            read     => ex_read,
            clear    => ex_clear,
            clk      => ex_clk,
            in_word  => ex_in,
            out_word => ex_out,
            full     => ex_full,
            empty    => ex_empty
        );

    clk_process : process
    begin
        ex_clk <= '0';
        wait for clk_period / 2;
        ex_clk <= '1';
        wait for clk_period / 2;
    end process clk_process;

    variables_process : process
    begin
        ex_write <= '0';
        ex_read  <= '0';
        ex_clear <= '0';
        ex_in    <= (others => '0');
        wait for clk_period;

        -- Push 0x01 and 0x02
        ex_in    <= x"01";
        ex_write <= '1';
        wait for clk_period;

        ex_in <= x"02";
        wait for clk_period;

        -- Pop top element (expect 0x02)
        ex_write <= '0';
        ex_read  <= '1';
        wait for clk_period;
        assert ex_out = x"02"
            report "LIFO Error: Expected 0x02 on first pop" severity error;

        -- Pop second element (expect 0x01)
        wait for clk_period;
        assert ex_out = x"01"
            report "LIFO Error: Expected 0x01 on second pop" severity error;

        -- Push sequence 0x02, 0x03, 0x04, 0x05, 0x03
        ex_read  <= '0';
        ex_write <= '1';
        wait for clk_period * 2;

        ex_in <= x"03";
        wait for clk_period * 2;

        ex_in <= x"04";
        wait for clk_period * 2;

        ex_in <= x"05";
        wait for clk_period * 2;

        ex_in <= x"03";
        wait for clk_period * 2;

        ex_write <= '0';
        report "LIFO_testbench completed successfully." severity note;
        wait;
    end process variables_process;

end Behavioral;
