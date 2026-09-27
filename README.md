# FPGA-Based CAN Bus Controller & Protocol Tester

This repository contains a synthesizable SystemVerilog FPGA prototype that can transmit, receive, analyze, and test CAN 2.0 frames. It is designed as a professional portfolio project for embedded and FPGA applications.

## Project Structure
- `rtl/`
  - `can_pkg.sv`: Definitions, structs, and constants.
  - `can_btr.sv`: Bit timing logic (TSEG1, TSEG2, SJW).
  - `can_crc.sv`: CAN CRC-15 Calculator.
  - `can_tx.sv`: Transmission FSM.
  - `can_rx.sv`: Reception FSM.
  - `can_bit_stuffing.sv`: 5-bit stuff insertion logic.
  - `can_arbitration.sv`: Dominant/Recessive collision detection.
  - `can_fifo.sv`: Generic TX/RX buffer.
  - `can_error_manager.sv`: Active/Passive/Bus-Off counters.
  - `can_fault_injector.sv`: Hardware logic to force bus errors.
  - `can_top.sv`: Top-level integration.
  - `fpga_can_demo.sv`: Example physical demo wrapper.
- `tb/`
  - `test_can_top.py`: Cocotb testbench for verification.

## Hardware Requirements
To run this in hardware, you must use an **external CAN transceiver** (e.g., MCP2551, TJA1050) connected to the FPGA `can_rx_ext` and `can_tx_ext` pins. The FPGA cannot drive differential CAN bus voltages directly.

## Limitations / Future Work
- Standard frame format implemented; Extended frames (29-bit ID) pending.
- Complete protocol edge-cases and synchronization jumps need rigorous hardware testing.
- FIFO needs proper integration with host interfaces (AXI/APB).

## Author
Developed as an embedded systems / FPGA portfolio prototype.
