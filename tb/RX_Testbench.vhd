library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RX_Testbench is
--  Port ( );
end RX_Testbench;

architecture Behavioral of RX_Testbench is

component UART_RX is
    generic(
        clk_per_bit : integer := 1085);
  Port (
    in_clk : in std_logic;
    in_rx_serial : in std_logic;
    out_rx_valid : out std_logic;
    out_data : out std_logic_vector( 7 downto 0)
     );
end component;

constant clk_period : time := 8 ns;
constant bit_period : time := 8680 ns;

signal clk : std_logic := '0';
signal rx_input : std_logic := '1';
signal rx_valid : std_logic;
signal rx_data : std_logic_vector (7 downto 0);

begin
Rx_1 : UART_RX
    generic map(
        clk_per_bit => 1085)
    port map(
        in_clk => clk,
        in_rx_serial => rx_input,
        out_rx_valid => rx_valid,
        out_data => rx_data);

clk_process : process
begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
end process clk_process;

variables_process : process
begin

    rx_input <= '1';
    wait for 100 ns;
    
    rx_input <= '0';
    wait for bit_period;
    
    rx_input <= '1'; wait for bit_period;
    rx_input <= '0'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '0'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '0'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '0'; wait for bit_period;
    
    rx_input <= '1';
    wait for bit_period;
    
    wait for bit_period * 2;
    
    rx_input <= '0';
    wait for bit_period;
    
    rx_input <= '1'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    rx_input <= '1'; wait for bit_period;
    
    rx_input <= '1';
    wait for bit_period;
    
    wait;
end process variables_process;
end Behavioral;
