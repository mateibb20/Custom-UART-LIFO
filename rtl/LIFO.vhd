library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LIFO is
    generic (
        size : integer := 8
    );
    Port (
        write    : in  std_logic;
        read     : in  std_logic;
        clear    : in  std_logic;
        clk      : in  std_logic;
        in_word  : in  std_logic_vector(7 downto 0);
        out_word : out std_logic_vector(7 downto 0) := (others => '0');
        full     : out std_logic;
        empty    : out std_logic
    );
end LIFO;

architecture Behavioral of LIFO is

    type memory is array (0 to size - 1) of std_logic_vector(7 downto 0);

    signal index : integer range 0 to size := 0;
    signal lifo  : memory := (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                for i in 0 to size - 1 loop
                    lifo(i) <= (others => '0');
                end loop;
                out_word <= (others => '0');
                index    <= 0;
            elsif write = '1' then
                if index < size then
                    lifo(index) <= in_word;
                    index       <= index + 1;
                end if;
            elsif read = '1' then
                if index > 0 then
                    out_word        <= lifo(index - 1);
                    lifo(index - 1) <= (others => '0');
                    index           <= index - 1;
                end if;
            end if;
        end if;
    end process;

    full  <= '1' when index = size else '0';
    empty <= '1' when index = 0 else '0';

end Behavioral;
