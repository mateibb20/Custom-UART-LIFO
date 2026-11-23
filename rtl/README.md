# RTL Design Modules (`/rtl`)

This directory contains the synthesizable VHDL hardware description files for the UART-interfaced LIFO buffer.

## Module Hierarchy

```text
UART_RX_TX_LIFO_TOP
 ├── UART_RX_component (UART_RX)
 ├── LIFO_mem          (LIFO)
 └── inst_UART_TX      (UART_TX)
```

---

## 1. `UART_RX_TX_LIFO_TOP.vhd`
Top-level PL wrapper integrating the UART receiver, LIFO memory, UART transmitter, 2-FF pushbutton synchronizers, and a 10 ms debouncer on `btn_read`.

### Generics
| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `clk_per_bit` | `integer` | `1085` | Clock cycles per UART bit (`125 MHz / 115200 bps = 1085.07`). |
| `size` | `integer` | `8` | Depth of the internal LIFO buffer in bytes. |
| `debounce_cycles` | `integer` | `1250000` | Debounce filter period in clock cycles (`10 ms` at `125 MHz`). |

### Ports
| Port | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | `in` | 1 | System clock (`125 MHz` from `FCLK_CLK0`). |
| `btn_read` | `in` | 1 | Active-high read trigger (`BTN0`). Debounced rising edge pops one byte if stack is non-empty and TX is idle. |
| `btn_clear` | `in` | 1 | Active-high synchronous stack clear (`BTN1`). |
| `rx_serial` | `in` | 1 | Serial RX line driven by Zynq PS `UART1_TX` (EMIO). |
| `tx_serial` | `out` | 1 | Serial TX line connected to Zynq PS `UART1_RX` (EMIO). |
| `full` | `out` | 1 | High when LIFO occupancy equals `size` (`LED0`). |
| `empty` | `out` | 1 | High when LIFO occupancy equals `0` (`LED1`). |

---

## 2. `LIFO.vhd`
Synchronous register-array stack supporting single-cycle push, pop, and clear operations.

* **Generic `size` (`integer`, default `8`):** Number of 8-bit words in the stack.
* **Ports:** `clk`, `clear` (priority 1), `write` (priority 2), `read` (priority 3), `in_word[7:0]`, `out_word[7:0]`, `full`, `empty`.

---

## 3. `UART_RX.vhd`
5-state FSM (`idle`, `start_check`, `receive`, `stop`, `flag_stable`) UART receiver with a 2-FF input synchronizer (`r_rx_data_r`, `r_rx_data`), mid-bit start validation (`(clk_per_bit - 1) / 2`), and stop-bit framing check. Pulses `out_rx_valid` high for 1 clock cycle upon receiving a valid 8-bit frame.

## 4. `UART_TX.vhd`
5-state FSM (`idle`, `start_bit`, `transmit`, `stop_bit`, `flag_done`) UART transmitter. Latches `in_data` when `in_tx_start = '1'` in `idle`, shifts out LSB-first across 8 bit periods, and pulses `out_tx_done` for 1 clock cycle after the stop bit.
