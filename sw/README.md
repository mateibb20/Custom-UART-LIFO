# Bare-Metal Vitis Firmware (`/sw`)

This directory contains the C application running on the Zynq-7000 ARM Cortex-A9 core (`ps7_cortexa9_0`).

## File Overview
* `src/helloworld.c`: Main polling loop bridging the host USB-UART (`UART0`) and the PL EMIO UART (`UART1`).
* `src/platform.c` / `src/platform.h`: Xilinx platform initialization and cache enable/disable routines.
* `src/platform_config.h`: Defines `STDOUT_IS_PS7_UART` on `UART_DEVICE_ID 0`.

## Firmware Execution Flow
1. **Initialization:** Calls `init_platform()` and initializes two `XUartPs` driver instances:
   * `USB` (`XPAR_PS7_UART_0_DEVICE_ID`, `0xE0000000`, MIO 14..15)
   * `VHDL` (`XPAR_PS7_UART_1_DEVICE_ID`, `0xE0001000`, EMIO)
2. **Configuration:** Sets both UART controllers to `XUARTPS_OPER_MODE_NORMAL` at `115200 bps`.
3. **Non-Blocking Polling Loop (`while(1)`):**
   * **Host $\rightarrow$ FPGA:** Checks `XUartPs_IsReceiveData(USB.Config.BaseAddress)`. When a byte arrives from the PC terminal, it echoes the byte back to `USB` and forwards it to `VHDL` (triggering a push into the PL LIFO).
   * **FPGA $\rightarrow$ Host:** Checks `XUartPs_IsReceiveData(VHDL.Config.BaseAddress)`. When `BTN0` is pressed on the board and the PL transmits a popped byte over EMIO, the firmware reads the byte and formats it to the PC terminal via `xil_printf("\r\n[LIFO Output: %c]\r\n> ", rx_buffer[0])`.
