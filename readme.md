# Example Project for ACP10 Vibrator Firmware

## Overview

This project demonstrates a solution for controlling a single-phase ACP10 vibrator. Please note, this solution is essentially a hack of the existing current controller and was not originally intended for single-phase control – however, it works fine 😊.

In Q1 2024, a dedicated ACP10 vibrator firmware will be released.

## Project Details

The project consists of one task where you can adjust the amplitude and frequency, and start the vibrator with `Run=TRUE`. On lines 36-38, a sine wave is calculated which acts as the setpoint for the current controller – thus a quite short cycle time is required (800µs in this case).

### Important Parameters

In the parameter table `cfCurCtr`, several ParIDs are set. Below are the most important ones:

- **Interpolation of PLC SetPoint**: To improve the resolution of the sine wave, an internal SPT function block will interpolate the calculation from the PLC. The output of the interpolation will be at ParID 8752.
  ![image](https://github.com/user-attachments/assets/b5b85718-3427-4947-8e4c-b4f5be4fd35e)

- **Switch Frequency**: Set to 10kHz. The default is 5kHz, which can also work, but 10kHz will improve performance as the microcontroller has more cycles to adjust the voltage.
  ![image](https://github.com/user-attachments/assets/42f6a77e-34db-492f-88a6-8dfd4db33d0c)

- **SetPoint for the ACP10 Current Controller**
  ![image](https://github.com/user-attachments/assets/40f9894d-e190-4ec0-b4a5-2302fc36ecfc)

- **Controller Mode**: Set to 5 (Current Controller).
  ![image](https://github.com/user-attachments/assets/f1b5efc7-1351-4044-a2d0-0fc09891b821)

- **Tuning of Proportional/Integral Gain for Current Controller**: Auto-tuning is disabled (ICTRL_AUTO_CONFIG=0) and tuning is done manually. For first-time use, set ICTRL_AUTO_CONFIG=5, but note that this tuning exclusively uses the resistance/inductance set in the parameter table (measure these with an LCR meter or find them in the datasheet). Fine-tuning can be done manually if auto-tuning doesn’t work.
![image](https://github.com/user-attachments/assets/bec41068-c884-4042-846e-874aa87973c2)

## Debugging

When you’ve downloaded this to a PLC, you can use the test center to debug. Create a trace of the following ParIDs with a 200µs sampling time:

- **586**: PLC setpoint
- **8752**: Interpolated setpoint
- **214**: Actual current
- **216**: Actual voltage – note this is a (quite good) voltage estimation, not an actual measurement like the current.

The trace will look something like this:

![image](https://github.com/user-attachments/assets/048d5b44-7c10-4612-80ab-a12a98b699bc)


You can see that the actual current matches the interpolated set point quite well, and the current controller is working as intended. If this is not the case, you might want to look at the tuning of \( k_v \) and \( t_i \). The voltage is not sinusoidal due to the vibrator coil’s back-EMF.

