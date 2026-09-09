# Traffic Light Controller (FPGA / Verilog)

An FPGA-based traffic light controller implemented in Verilog, targeting Xilinx Vivado.

## Modules

| File | Description |
|---|---|
| `traffic_light_top.v` | Top-level module wiring all submodules together |
| `traffic_fsm.v` | Traffic light finite state machine |
| `clock_divider.v` | Divides the board clock down to a usable rate |
| `timer.v` | Timing/counter logic for light phase durations |
| `button_debounce.v` | Debounces pedestrian/input button signals |
| `seven_segment.v` | Seven-segment display driver |
| `uart_rx.v` | UART receiver for serial command input |
| `command_decoder.v` | Decodes incoming UART commands |
| `fifo.v` | FIFO buffer for command/data queuing |

## Constraints

- `constraints/traffic_light.xdc` — pin/timing constraints for the target board

## Building

This project was developed in Xilinx Vivado. To rebuild:

1. Create a new Vivado RTL project.
2. Add all files under `src/` as design sources.
3. Add `constraints/traffic_light.xdc` as a constraints file.
4. Run synthesis, implementation, and generate the bitstream.

Generated build artifacts (`.cache`, `.runs`, `.sim`, `.srcs`, `.xpr`, etc.) are intentionally excluded from this repo — see `.gitignore`.
