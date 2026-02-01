# VGA Signal Generator Lab Report

**Name: Jake Miller**  
**Course / Section: ECE 383**  
**Instructor: Lt Col Trimble**  
**Lab Title: VGA Synchronization**  
**Date Submitted: 31 Jan 2026**  

# 1. Introduction
In lab one we are tasked create a VGA controller in VHDL and implement it onto the FPGA development board. The development board consists of a VGS-to-HDMI converter module and is implemented using digital logic. The overall purpose is to design and verify VGA timing, synchronization, and graphical display in which we generate the display portion of an oscilloscope which consists of a white grid, two measured signals (channel 1 and channel_ 2) and trigger markers (for voltage and time). 
## 1.1 Problem Overview  
VGA is considered a time-critical signal because every pixel is drawn at the exact correct clock cycle to produce the desired image. This introduces the challenge of precise timing between pixels, pulses, and blank intervals. This is accomplished in part with horizontal and vertical synchronization signals. The final product is an oscilloscope display with waveforms, trigger indicators, and a grid.
## 1.2 System Goal  
The overall goals are the design and implement a VGA system in VHDL, generate correct timing for horizontal, vertical, and blanking synchronization, produce a display with 11 vertical lines, 9 horizontal lines, two triangular trigger markers (for time and for voltage), and two waveforms (channel 1 and channel 2). The system will be used in future labs to display real audio signals.
## 1.3 Functional Requirements  
In total, the system must:
1) generate an RGB output (red signal, green signal, and blue signal)
2) generate synchronization signals (horizontal for rows and vertical for frame completion)
3) synchronization signals with active video state, front porch, synch pulse, and back porch
4) zero RGB balues when outside video region
5) use a 25MHz clock
6) horizontal timing based on clock cycle and vertical timing based on row completion
7) a grid with 11 vertical lines and 9 horizontal lines
8) track current row, current position, trigger pixels, channel 1 enable, channel 2 enable
9) contain a reset
## 1.4 High-Level System Description  
The system architecture is deconstructed into smaller components (i.e., a color mapper, a VGA signal generator, a numerical stepper, etc.). The VGA signal generator is responsible for sweeping and generating pixels on the display. The color mapper is used to determine the color of each pixel in a frame. The trigger markers are converted into pixel locations and indicated on the display. The system is tested and verified with multiple testbenches for each component. After testing a bitstream is generated for implementation on an FPGA and VGA is converted to HDMI for use on a monitor.

# 2. Design / Implementation

## 2.1 System Block Diagram  
![System Block Diagram](lab1/lab1_schematic.png)
### 2.1.1 Diagram Corrections  

## 2.2 Top-Level Architecture Description  
### 2.2.1 Major Signals  

## 2.3 Module Descriptions  
### 2.3.1 Module: Horizontal Counter  
### 2.3.2 Module: Vertical Counter  
### 2.3.3 Module: VGA Sync Generator  
### 2.3.4 Module: Color Mapper  
### 2.3.5 Module: (Additional Module)  

# 3. Test / Debug

## 3.1 Verification Methods  

## 3.2 Testbench Evidence  
### 3.2.1 HSYNC vs Column Count  
### 3.2.2 VSYNC vs Row and Column Count  
### 3.2.3 Blanking Signals  
### 3.2.4 Counter Rollover Behavior  

## 3.3 Problems Encountered and Solutions  
### 3.3.1 Problem 1  
### 3.3.2 Problem 2  
### 3.3.3 Problem 3  


# 4. Results

## 4.1 Milestone Achievement Table  
## 4.2 Evidence Summary  


# 5. Conclusion

## 5.1 Lessons Learned  
## 5.2 Recommended Improvements  


# 6. GitHub Repository Contents  