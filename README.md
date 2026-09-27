# FPGA-Based CAN Bus Controller & Protocol Tester

This repository contains a synthesizable SystemVerilog FPGA prototype that can transmit, receive, analyze, and test CAN 2.0 frames. It is designed as a professional portfolio project for embedded and FPGA applications.

## Directory Structure
- `rtl/`: SystemVerilog source files for the CAN controller.
- `tb/`: Testbenches (SystemVerilog and cocotb).
- `verification/`: Functional coverage and verification environments.
- `docs/`: Documentation and specifications.

## Features
- Standard 11-bit CAN frames (TX & RX)
- CRC and Bit Stuffing
- Arbitration handling
- Error detection and fault injection
- TX/RX FIFOs
