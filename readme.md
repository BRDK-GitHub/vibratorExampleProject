# Example Project for ACP10 Vibrator Firmware

## Overview

This project demonstrates a solution for controlling a single-phase ACP10 vibrator. Please note, this solution is essentially a hack of the existing current controller and was not originally intended for single-phase control – however, it works fine 😊.

In Q1 2024, a dedicated ACP10 vibrator firmware will be released.

## Project Details

The project consists of one task where you can adjust the amplitude and frequency, and start the vibrator with `Run=TRUE`. On lines 36-38, a sine wave is calculated which acts as the setpoint for the current controller – thus a quite short cycle time is required (800µs in this case).

### Important Parameters

In the parameter table `cfCurCtr`, several ParIDs are set. Below are the most important ones:

- **Interpolation of PLC SetPoint**: To improve the resolution of the sine wave, an internal SPT function block will interpolate the calculation from the PLC. The output of the interpolation will be at ParID 8752.
- **Switch Frequency**: Set to 10kHz. The default is 5kHz, which can also work, but 10kHz will improve performance as the microcontroller has more cycles to adjust the voltage.
- **SetPoint for the ACP10 Current Controller**
- **Current Mode**: Set to 5 (Current Controller).
- **Tuning of Proportional/Integral Gain for Current Controller**: Auto-tuning is disabled (ICTRL_AUTO_CONFIG=0) and tuning is done manually. For first-time use, set ICTRL_AUTO_CONFIG=5, but note that this tuning exclusively uses the resistance/inductance set in the parameter table (measure these with an LCR meter or find them in the datasheet). Fine-tuning can be done manually if auto-tuning doesn’t work.

## Debugging

When you’ve downloaded this to a PLC, you can use the test center to debug. Create a trace of the following ParIDs with a 200µs sampling time:

- **586**: PLC setpoint
- **8752**: Interpolated setpoint
- **214**: Actual current
- **216**: Actual voltage – note this is a (quite good) voltage estimation, not an actual measurement like the current.

The trace will look something like this:

Pic needed

You can see that the actual current matches the interpolated set point quite well, and the current controller is working as intended. If this is not the case, you might want to look at the tuning of \( k_v \) and \( t_i \). The voltage is not sinusoidal due to the vibrator coil’s back-EMF.

