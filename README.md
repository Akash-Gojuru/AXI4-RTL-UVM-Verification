# AXI4-RTL-UVM-Verification
SystemVerilog AXI4 RTL and UVM verification project with burst transactions, backpressure, assertions, scoreboards, functional coverage, error injection, and Cadence Xcelium regression.

# AXI4 RTL + UVM Verification Framework

A SystemVerilog project implementing and verifying a practical AXI4 read/write subset using directed testbenches, SystemVerilog Assertions, UVM, scoreboards, functional coverage, and Cadence Xcelium regression.

## Features

- 32-bit AXI read/write datapath
- Single-beat and burst transactions
- Variable-length INCR bursts
- WSTRB byte enables
- AWSIZE / ARSIZE address progression
- WLAST / RLAST handling
- Read and write backpressure
- AW/W/B/AR/R channel stall testing
- SLVERR error handling
- SystemVerilog Assertions
- UVM driver, monitor, sequencer, agent, environment, scoreboard, and coverage
- Automated regression scripts

## Verification

The project includes:

- Directed SystemVerilog tests
- Backpressure tests
- Error-injection tests
- Read/write protocol assertions
- UVM constrained-random verification
- Scoreboard checking
- Functional coverage
- Cadence Xcelium regression

Current write UVM result:

```text
Transactions checked: 10
Errors: 0
Functional coverage: 28.84%

UVM_ERROR : 0
UVM_FATAL : 0
