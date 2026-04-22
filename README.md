![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# tt_um_systolicmac — 4×4 Systolic Array Matrix MAC Accelerator

A hardware matrix multiply-accumulate (MAC) accelerator implemented as a 4×4 systolic array in SystemVerilog, submitted to [Tiny Tapeout](https://tinytapeout.com). It computes **C = A × B** for two 4×4 matrices of 4-bit unsigned integers (values 0–15) and returns the 16 results over SPI.

- [Detailed datasheet](docs/info.md)

## How it works

The core is a 4×4 grid of 16 processing elements (PEs). Each PE holds two pass-through registers and a 10-bit accumulator. On every clock cycle the PE latches its inputs, passes them to its right/bottom neighbor, and adds `a_reg × b_reg` to its accumulator.

Matrix A flows **left-to-right** across rows; matrix B flows **top-to-bottom** down columns. A boundary skewing circuit delays row `i` of A by `i` cycles and column `j` of B by `j` cycles so every pair of dot-product operands arrives at the correct PE at the correct time. After 2N−1 = 7 active cycles plus 2 pipeline-flush cycles (9 total), all 16 accumulators hold the correct result.

### Modules

| Module | Role |
|--------|------|
| `pe` | Single MAC unit — 4-bit inputs, 10-bit accumulator |
| `systolic_array_4x4` | 4×4 PE grid with boundary feeding and cycle counter |
| `control_fsm` | 5-state FSM: IDLE → CLEAR → LOAD → COMPUTE → DRAIN |
| `spi_slave` | Deserializes 33 incoming SPI bytes into matrices A and B |
| `spi_tx` | Serializes 16 accumulator results back over MISO |

## Pin interface

| Pin | Signal | Direction | Description |
|-----|--------|-----------|-------------|
| `ui[0]` | SCK | Input | SPI clock |
| `ui[1]` | MOSI | Input | SPI data in |
| `ui[2]` | CS | Input | SPI chip select (active low) |
| `uo[0]` | MISO | Output | SPI data out |
| `uo[1]` | comp_done | Output | Pulses high when computation is complete |
| `uo[2]` | load_done | Output | Pulses high when matrix load is complete |
| `uo[3]` | spi_done | Output | Pulses high when result transmission is complete |

All SPI inputs are double-registered internally to prevent metastability.

## SPI protocol

The chip uses SPI mode 0 (CPOL=0, CPHA=0). One complete transaction:

1. Pull **CS low**.
2. Send **33 bytes** over MOSI:
   - Byte 0: command byte (any value, ignored)
   - Bytes 1–16: matrix A, row-major (A[0][0], A[0][1], …, A[3][3]), one element per byte (lower nibble used)
   - Bytes 17–32: matrix B, row-major, same format
3. Wait for **`comp_done`** (uo[1]) to assert (~10 clock cycles after load).
4. Clock out **32 result bytes** over MISO: 16 results × 2 bytes each (6 zero bits + 10-bit value, MSB first).
5. Pull **CS high**.

## Example

Multiply:

```
A = [[ 1,  2,  3,  4],      B = [[ 5,  6,  7,  8],
     [ 5,  6,  7,  8],           [ 9, 10, 11, 12],
     [ 9, 10, 11, 12],           [13, 14, 15, 16],  (values > 15 for illustration)
     [13, 14, 15, 16]]           [17, 18, 19, 20]]
```

Send: `[0x00, 1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16, 5,6,7,8, 9,10,11,12, 13,14,15,16, 17,18,19,20]`

Expected result:

```
C = [[130, 140, 150, 160],
     [322, 348, 374, 400],
     [514, 556, 598, 640],
     [706, 764, 822, 880]]
```

## Testing

### Simulation (cocotb)

```bash
cd test
pip install -r requirements.txt
make
```

The testbench drives the SPI interface, loads random matrices, and verifies results against a NumPy reference. A standalone SystemVerilog testbench (`test/4by4_tb.sv`) runs 1000 randomized matrix multiplications plus edge cases (all-zero, all-max, identity).

### FPGA (Basys3)

`test/python_tester.py` communicates with the design running on a Basys3 FPGA over UART. It prompts for matrix values, sends them to the chip, reads back the result, and checks against NumPy.

```bash
python test/python_tester.py  # adjust COM port in script
```

## External hardware

An SPI master is required (RP2040, Arduino, or similar). For FPGA testing a USB-UART bridge is used together with a UART shim module (not included in the TT submission).

## Resources

- [Tiny Tapeout](https://tinytapeout.com)
- [Discord community](https://tinytapeout.com/discord)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
