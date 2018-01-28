AVR microcontroller programming with avr-gcc
============================================

This repository is split into a series of lessons intended to be followed in
order as a tutorial series. The tutorials cover embedded systems programming
using the AVR atmega32 microcontroller (though is also applicable to other AVR
MCUs). The toolchain used is Linux with gcc-avr for compilation/
assembly and avrdude for flashing the MCU. A Raspberry Pi is used as a 
programmer in lesson 1, though other programmers are available. 

These tutorials assume knowledge of C and assembly programming, as well as
basic electronics knowledge. Regarding parts, a Raspberry Pi (or other linux 
PC and an external AVR programmer); an ATmega32-16PU (or other 8-bit Atmel
MCU); a breadboard plus basic electronic components (wires, resistors, 
LEDs...) and a 5V AC adaptor (e.g. phone charger) are required.

Topics covered
--------------

**Lesson 1:** toolchain installation; desktop vs. MCU programming; gcc-avr
basics; programming the MCU with avrdude; make an LED flash. 


Useful Resources
----------------

Another AVR tutorial series, in C:
newbiehack.com/MicrocontrollerTutorial.aspx

Instruction set summary for AVR MCUs:
avr-tutorials.com/sites/default/files/Instruction Set Summary.pdf

ATmega32 datasheet:
ww1.microchip.com/downloads/en/DeviceDoc/doc2503.pdf

AVR-libc user manual:
cs.ou.edu/~fagg/classes/general/atmel/avr-libc-user-manual-1.7.1.pdf

All circuit diagrams were drawn using EasyEDA:
easyeda.com

