<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

--->

## How it works

This project implements a 4×4 systolic array matrix multiply-accumulate (MAC) accelerator in SystemVerilog. It computes the product C = A × B for two 4×4 matrices of unsigned 8-bit integers, producing 16 results with 20-bit accumulator precision.

The design consists of five modules:

- **pe** — Processing element. Each PE contains two 8-bit pass-through registers and a 20-bit accumulator. On each clock cycle (when enabled), it latches inputs into internal registers, passes them to neighboring PEs, and accumulates the product of the registered values. 16 PEs are arranged in a 4×4 grid.
- **systolic_array_4x4** — The array top-level. Contains the 16 PEs connected in a grid, boundary feeding logic that skews matrix inputs using a cycle counter (row i of A is delayed by i cycles, column j of B is delayed by j cycles), and a done signal that asserts when the computation is complete (after 10 counter cycles to account for pipeline flush).
- **control_fsm** — A 5-state FSM (IDLE → CLEAR → LOAD → COMPUTE → DRAIN) that sequences the operation. It waits for the SPI slave to finish loading matrices, clears accumulators, starts the array, and then enables result transmission.
- **spi_slave** — Deserializes 33 incoming SPI bytes (1 command byte + 16 bytes for matrix A + 16 bytes for matrix B) into two 4×4 unpacked arrays and asserts `load_done` when complete.
- **spi_tx** — Serializes the 16 accumulator outputs (20 bits each, transmitted as 16-bit truncated values) back to the host over SPI MISO.

The systolic dataflow works as follows: matrix A elements flow left-to-right across rows, matrix B elements flow top-to-bottom down columns. Each PE multiplies its registered A and B values and adds the product to its running accumulator. After 2N−1 = 7 counting cycles plus 2 pipeline flush cycles, all 16 accumulators hold the correct dot product results.

## How to test -- adding lines for gds to work :D

### SPI interface

Connect an SPI master (e.g., RP2040, Arduino, or FPGA) to the chip:

| Pin | Signal | Direction |
|-----|--------|-----------|
| ui[0] | SCK | Input |
| ui[1] | MOSI | Input |
| ui[2] | CS | Input |
| uo[0] | MISO | Output |
| uo[1] | comp_done | Output (status) |
| uo[2] | load_done | Output (status) |
| uo[3] | spi_done | Output (status) |

### Protocol

1. Pull CS low to begin a transaction.
2. Send 33 bytes over MOSI: 1 command byte (any value), then 16 bytes for matrix A (row-major: A[0][0], A[0][1], ..., A[3][3]), then 16 bytes for matrix B (row-major).
3. The chip computes C = A × B. Monitor `comp_done` (uo[1]) to know when the result is ready.
4. Clock out 32 result bytes over MISO (16 results × 2 bytes each, MSB first).
5. Pull CS high to end the transaction.

### Example

To multiply:

```
A = [[1, 2, 3, 4],        B = [[5,  6,  7,  8],
     [5, 6, 7, 8],             [9,  10, 11, 12],
     [9, 10, 11, 12],          [13, 14, 15, 16],
     [13, 14, 15, 16]]         [17, 18, 19, 20]]
```

Send bytes: `[0x00, 1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16, 5,6,7,8, 9,10,11,12, 13,14,15,16, 17,18,19,20]`

Expected result matrix:

```
C = [[130,  140,  150,  160],
     [322,  348,  374,  400],
     [514,  556,  598,  640],
     [706,  764,  822,  880]]
```

### Python test script

A Python test script (`test_systolic.py`) is included for testing over UART on a Basys3 FPGA. It sends matrices, reads back results, and compares against NumPy reference values.

## External hardware

An SPI master is required to communicate with the chip. Any microcontroller with SPI support will work. For the Basys3 FPGA test setup, a USB-UART bridge is used instead with a separate UART shim module (not included in the TT submission).