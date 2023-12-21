# Embedded-stopwatch-system-DE1-SoC

## Overview

The project focuses on the implementation of HEX display subroutines, pushbutton handling, and the creation of interrupt service routines.
The code can be compile and test in: https://ecse324.ece.mcgill.ca/simulator/?sys=arm-de1soc

## Part 1: HEX Display Subroutines

### Solution Approach
- **HEX Display Implementation**: 
  - The HEX display input indices are divided into two parts due to the address division between the first four (32-bit) and the last two HEX displays.
  - A helper subroutine named “Binary” was developed for `HEX_clear_ASM` to generate and invert hex equivalents, manipulating HEX display outputs.

### Challenges and Solutions
- **Debugging Complexity**: 
  - The interdependent nature of subroutines posed significant challenges in debugging. Multiple unit tests were employed for each component to isolate and rectify issues.

### Shortcomings and Possible Improvements
- **Optimization Opportunities**: 
  - Directly reading interrupt bits instead of pushbuttons' state could improve efficiency, as accessing interrupt registers is generally faster.

## Part 2: Pushbuttons and Timer

### Solution Approach
- **Timer and Pushbutton Integration**: 
  - Created subroutines for initializing a timer, and reading and clearing its interrupt bits, aiming to build a functional stopwatch.
  - Utilized loops to monitor the timer's interrupt status and the pushbutton edge caps, with specific functionalities assigned to each pushbutton.

### Challenges and Solutions
- **Timer Configuration Understanding**: 
  - Grasping the timer's configuration was challenging. Overcoming this involved thorough manual review and experimental configurations.

### Shortcomings and Possible Improvements
- **Display Continuity**: 
  - Enhancements are needed to enable continuous and smooth counting on HEX displays without needing to clear segments for new numbers.

## Part 3: Interrupt Service Routine

### Solution Approach
- **Interrupt Service Routine Development**: 
  - Developed an interrupt service subroutine, `ARM_TIM_ISR`, for the private timer and pushbuttons. This subroutine continuously checks for interrupts and updates the timer accordingly.

### Challenges and Solutions
- **Code Comprehension**: 
  - Initial difficulties were faced in understanding the ISR concept and the pre-provided code. These were gradually resolved through detailed study and practice.

### Shortcomings and Possible Improvements
- **Code Efficiency**: 
  - The current code causes intermittent display of counter values, indicating a need for a more efficient approach to improve continuity and visibility.
