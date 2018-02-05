AVR Programming Guide
=====================

This lesson covers:
 - Installation of the toolchain used
 - How to program the MCU using a raspberry pi
 - The basics of MCU programming and gcc-avr 
 - Designing a circuit/code that will make an LED turn on

Installation (Raspbian)
-----------------------

GCC-AVR, and related programs, are needed to compile our assembly code to the
Intel HEX binary format natively read by the MCU. AVRDUDE is a program used to
get this machine code onto the MCUs EEPROM flash memory. It is assumed you are
using a Raspberry Pi as a programmer with Raspbian OS - it is entirely
possible to use a different hardware programmer, though seek other instructions
on programming the MCU before skipping below to the 'Toolchain Used' section.

```
sudo apt-get install avrdude avrdude-doc binutils-avr avr-libc gcc-avr gdb-avr
```

Using a Raspberry Pi as an AVR programmer
-----------------------------------------

_NOTE: if using dedicated hardware programmer, seek seperate instructions
and skip to 'Toolchain Used' section._

Once the intel hex machine code file is created (covered later), the EEPROM of 
the AVR microcontroller needs to be flashed. This will be done so that our
code automatically executes when the MCU is powered. Whilst dedicated 
programmers can be brought, it will be done here using avrdude software with 
physical interfacing via RPi GPIO pins.

Connect the RPi to the AVR microcontroller (via a breadboard):
 - AVR VCC to RPi 5 volt pin
 - AVR GND to RPi ground pin
 - AVR RESET to RPi GPIO #15
 - AVR SCK to RPi GPIO #24
 - AVR MOSI to RPi GPIO #23
 - AVR MISO to RPi GPIO #18

Installing avrdude (see prev) created a configuration file /etc/avrdude.conf.
Copy the contents of this file to new avrdude\_gpio.conf. Append the following
to the end of the file:

```
programmer
  id    = "pi_1";
  desc  = "Use the Linux sysfs interface to bitbang GPIO lines";
  type  = "linuxgpio";
  reset = 15;
  sck   = 24;
  mosi  = 23;
  miso  = 18;
;
```

Verify the RPi can connect to the AVR microcontroller:

``` 
sudo avrdude -p atmega32 -C avrdude_gpio.conf -c pi_1 -v
```

Program the AVR microcontroller by flashing file `myfile.hex`:

```
sudo avrdude -p atmega32 -C avrdude_gpio.conf -c pi_1 -v -U flask:w:myfile.hex:i
```

These topics are also covered here: 
https://learn.adafruit.com/program-an-avr-or-arduino-using-raspberry-pi-gpio-pins/overview

Toolchain Used
--------------

I am using the avr-as assembler, not the popular Windows ATMEL Studio 
assembler. The syntax is very similar, but note a few differences
(Don't worry, the details of the assembler are discussed throughout the series):
 - Use `lo8(0xabcd)` (results in 0xcd) and `hi8()` instead of `low()` 
   and `high()`
 - Use `.byte` instead of `.db` to store information in data segment;
   explicitly separate strings into char arrays 

**Assembly and linking:**

```
avr-gcc -mmcu=atmega32 myfile.S -o myfile.elf
```

Note that avr-gcc, NOT avr-as, must be invoked upon a '.S' filetype (the 'S'
must be capitalised) for the C preprocessor to be called before assembly.
ELF binary file created.

**Conversion:**

```
avr-objcopy -O ihex -R .eeprom myfile.elf myfile.hex
```

Intel HEX format binary file created. This is the MCU's machine code.

We will now write assembly code to control and LED attacted to the MCU. Before
we do this however, some theory must be covered.

Basics of Registers and MCU I/O programming - Theory pt. 1
----------------------------------------------------------

In desktop computers, registers (e.g. EAX) and memory (DRAM) do not share a 
memory addressing scheme - the registers live only inside the CPU. This is
neccessary because memory access is comparatively slow. However, in AVR
microcontrollers, general purope registers (R0-R31), I/O registers
(64 numbered from $00 to $3F) and SRAM are all assigned addresses on the
'Data Address Space'. General puropse registers are assigned addresses
$0000-$001F; I/O registers are assigned addresses $0020-$005F and (for 
atmega32) internal SRAM is allocated addresses $0060-$085F. Note that this
does not mean that the registers are physically implemented on SRAM.

Note that general purpose registers R26 ($1A) and R27 combine to form
16 bit register X, split into XH and XL. Similarly R28 and R29 form
register Y and R30 and R31 ($1F) form register Z. Whilst registers and
SRAM addresses both have data space addresses, having a distinction 
between them is important. This is in part because registers allow for
smaller instruction encoding (5 bits are required to distinguish between
R0-R31) and thus more efficient execution with a 16-bit instruction register
(where the instruction being executed is stored). Another reason is that the
X, Y and Z registers allow indirect addressing modes.

There are various addressing modes used by different opcodes. Direct 
addressing is the simplest, where the value given is an immediate (i.e.
just a number) or a data address space corresponding to a register. 
These often take just one clock cycle - e.g. `ADD R1, R2`. In indirect 
addressing, the value given is that of a data address space in internal SRAM,
containing a byte of data with which the opcode is concerned.
For example `LD R1, X` (load the value pointed to by register X to register
R1). Addressing can also be done indirect with pre-decrement and indirect
with post-increment. Registers X, Y and Z are capable of this indirect
addressing. Registers Y and Z also support indirect addressing with
displacement. The displacement value must be (plus)0-63 inclusive, as it is
defined by 6 bits of the instructions opcodes. For example `LDD R1, Y+2`
(load the value of data address space 2 bytes greater than that pointed to by 
register Y into register R1). These more complex instructions take 2 or 
greater instruction cycles to complete, partly because the instruction
register (holds current instruction) and program counter register (holds next
instruction address) are only 16-bits, and 16-bits are required to give an SRAM 
data space address.

Some opcodes work with I/O registers, e.g. 'OUT PORTB, R17'. However the 
opcodes for IN and OUT instructions requires the IO register address space 
($00-$3F). The same I/O register (e.g. PORTA) may have a different address 
in different AVR microcontrollers. The C preprocessor and compiler options 
are used to convert I/O register names to their corresponding I/O space 
addresses understood by the assembler.

For more information, it is strongly recommended you read the datasheet and
instruction set summary, linked in the main README.

Basics of AVR I/O programming - Practice
----------------------------------------

The macro `#include <avr/io.h>` is added to the start of the assembly 
file which converts the registers (e.g. PORTA) to I/O space addresses using the 
\_SFR\_IO\_ADDR() macro. Remember the file type must be .S (capital S) so avr-gcc 
invokes the C pre-comiler even though the file type is assembly. The AVR 
microcontroller used is given to the assembler with the `-mmcu=` option (see
'Toolchain Used' section, above).

GCC-AVR requires a 'main' label, though unlike in C it doesn't neccesserily
mark the programs entry point. When the MCU is flashed and powered up, the 
machine code will simply execute sequentially.

GCC-AVR code thus typically begins as follows:

```
#include <avr/io.h>

.global main

main:
    // Code here
```

Three main registers are involved in manipulating MCU pins. DDRxn determins 
whether a pin is an input (bit is 0) or output (bit is 1). For example the 
following configures PORTA3 to be an output:

```
ldi r16, 0b00001000
out _SFR_IO_ADDR(DDRA), r16
```

If a pin is configured to be an output, it may be activated (becomes +5V 
terminal) using PORTxn. Following on from the previous example, to output from
PORTA3:

```
out _SFR_IO_ADDR(PORTA), r16
```

If a pin is configured as a input, than the PINxn bits are determined by the
input voltages to those pins, being 1 upon 5V input (the current is irrelevant
due to purely voltage-driven CMOS use). If a pin is configured as an output,
PINxn bits are synchonized to PORTxn bits. Pin values can be read as follows,
though note that if pin values are to be read immidiately after setting PORTxn,
a NOP instruction must be inserted before PINxn values are read so that PORTxn
and PINxn values are synchronized.

```
in r17, _SFR_IO_ADD(PINA)
```

Practical task: Making an LED turn on
-------------------------------------

The electronic circuit required is described in 'L1-Circuit-diagram-LED.png',
though note that minor modifications may be required if a different Atmel MCU
with different pin arrangements is used. A 5V power source may be created using
a 5V AC adaptor (such as a USB phone charger). Stripping the outer wire coating
should reveal four wires, with a red +5V and black ground (the other wires are
for data transfer and are not required). The red wire must be connected to the
VCC and AVCC pins and the black to the ground pins to power the device.

We will program PORTA0 to be an output, providing 5V. A resister is used to 
limit the current through the LED, which of course must be connected to ground.
If the MCU is correctly programmed with the code in LED\_on.S and connected to
the described circuit, the LED should turn when power is given.

