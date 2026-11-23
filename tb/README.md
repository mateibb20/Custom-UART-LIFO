# Behavioral Simulation Testbenches (`/tb`)

This directory contains standalone VHDL testbenches for verifying the UART receiver and LIFO memory blocks in Vivado XSim.

## Available Testbenches

1. **`RX_Testbench.vhd`**
   * **Unit Under Test:** `UART_RX` (`clk_per_bit => 1085`, `125 MHz` clock = `8 ns` period, `115200 bps` bit period = `8680 ns`).
   * **Stimulus:** Drives a start bit (`0`), transmits `0x55` (`10101010` LSB-first), a stop bit (`1`), waits 2 bit periods, and transmits `0xFF` (`11111111`).
   * **Expected Result:** `out_rx_valid` pulses high for one `8 ns` clock cycle after each stop bit with `out_data = x"55"` and `out_data = x"FF"`.

2. **`LIFO_testbench.vhd`**
   * **Unit Under Test:** `LIFO` (`size => 8`, `125 MHz` clock = `8 ns` period).
   * **Stimulus:** Pushes `0x01` and `0x02`, pops twice (`ex_read <= '1'`) with automated `assert` checks on `ex_out`, then pushes `0x02`, `0x03`, `0x04`, `0x05`, and `0x03`.
   * **Expected Result:** `ex_out` outputs `0x02` followed by `0x01` on consecutive read cycles without assertion failures.

## Running Simulations in Vivado
1. Run `scripts/build_project.tcl` to generate the Vivado project (which automatically places `tb/*.vhd` into the `sim_1` fileset).
2. In the **Sources** window under **Simulation Sources**, right-click either `RX_Testbench` or `LIFO_testbench` and select **Set as Top**.
3. In the Flow Navigator, click **Run Simulation > Run Behavioral Simulation**.
4. Run the simulation for at least `250 us` when simulating `RX_Testbench` (two 10-bit UART frames at `8680 ns/bit` require `~190 us`).
