# PSoC 5LP firmware

Firmware for the **PSoC 5LP (ARM Cortex-M3)** node, developed in **PSoC Creator**.
It handles the acquisition and detection front-end of the ultrasonic ToF system:

- **ADC + DMA** capture of the ultrasonic echo (bandpass sampling at 800 kS/s).
- Sub-sample **cross-correlation** against a reference template using the
  **ARM CMSIS-DSP** library (`arm_correlate_f32`, `arm_fir_interpolate_f32`,
  `arm_fir_f32`).
- UART link to the ESP32 node for reconstruction and higher-level processing.

## Files

- `main.c` — application firmware (state machine, DMA setup, correlation, UART).
- `common.h` — shared constants/definitions.

## Dependencies (not included here)

- **ARM CMSIS-DSP** (`arm_math.h`, `arm_correlate_f32.c`, `arm_fir_interpolate_f32.c`,
  `math_helper.*`) — add from the ARM CMSIS-DSP distribution.
- **PSoC Creator generated files** (`project.h`, `Generated_Source/`, component
  configuration) — produced by opening the schematic in PSoC Creator. These are build
  artifacts and are intentionally not committed.

To rebuild, recreate the PSoC Creator project (ADC, DMA, UART and clock components),
drop in `main.c` / `common.h`, and link CMSIS-DSP.
