#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xuartps.h"

int main()
{
    init_platform();

    XUartPs USB;  // UART0 (MIO 14..15 to Host PC Terminal)
    XUartPs VHDL; // UART1 (EMIO to PL / LIFO block)

    XUartPs_Config *Config0;
    XUartPs_Config *Config1;

    Config0 = XUartPs_LookupConfig(XPAR_PS7_UART_0_DEVICE_ID);
    Config1 = XUartPs_LookupConfig(XPAR_PS7_UART_1_DEVICE_ID);

    XUartPs_CfgInitialize(&USB, Config0, Config0->BaseAddress);
    XUartPs_CfgInitialize(&VHDL, Config1, Config1->BaseAddress);

    XUartPs_SetOperMode(&USB, XUARTPS_OPER_MODE_NORMAL);
    XUartPs_SetOperMode(&VHDL, XUARTPS_OPER_MODE_NORMAL);

    XUartPs_SetBaudRate(&USB, 115200);
    XUartPs_SetBaudRate(&VHDL, 115200);

    print("\r\nType characters into the terminal to push them to the LIFO\r\n> ");

    u8 rx_buffer[1];

    while (1) {
        // 1. Poll for incoming characters from the PC Terminal (UART0 / USB)
        if (XUartPs_IsReceiveData(USB.Config.BaseAddress)) {
            XUartPs_Recv(&USB, rx_buffer, 1);

            // Echo character back to the PC terminal screen
            XUartPs_Send(&USB, rx_buffer, 1);

            // Forward character to the PL LIFO block via UART1 (EMIO)
            XUartPs_Send(&VHDL, rx_buffer, 1);
        }

        // 2. Poll for popped bytes transmitted back from the PL LIFO block (UART1 / EMIO)
        if (XUartPs_IsReceiveData(VHDL.Config.BaseAddress)) {
            XUartPs_Recv(&VHDL, rx_buffer, 1);
            xil_printf("\r\n[LIFO Output: %c]\r\n> ", rx_buffer[0]);
        }
    }

    cleanup_platform();
    return 0;
}
