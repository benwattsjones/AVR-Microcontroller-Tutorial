AVR Programming Guide
=====================

Installation (Raspbian)
-----------------------
```
sudo apt-get install avrdude avrdude-doc binutils-avr avr-libc gcc-avr gdb-avr
```

Registers and memory mapping
----------------------------
In desktop computers, registers (e.g. EAX) and memory (DRAM) do not share a 
memory addressing scheme - the registers live only inside the CPU. This is
neccessary because memory access is comparatively slow. However, in AVR
microcontrollers, general purope registers (R0-R31), I/O registers
(64 numbered from $00 to $3F) and SRAM are all assigned addresses on the
'Data Address Space'. General puropse registers are assigned addresses
$0000-$001F; I/O registers are assigned addresses $0020-$005F and (for 
atmega32) internal SRAM is allocated addresses $0060-$085F.Note that this
does not mean that the registers are physically implemented on SRAM.

Note that general purpose registers R26 ($1A) and R27 combine to form
16 bit register X, split into XH and XL. Similarly R28 and R29 form
register Y and R30 and R31 ($1F) form register Z. Whilst registers and
SRAM addresses both have data space addresses, having a distinction 
between them is important. This is in part because registers allow for
smaller instruction encoding (5 bits are required to distinguish between
R0-R31) and thus more efficient execution with a 16-bit instruction register
(where the instruction being executed is stored). Another reason is that the
X, Y and Z registers allow indirect addressing modes (explained later).

There are various addressing modes used by different opcodes. Direct 
addressing is the simplest, where the value given is an immediate (i.e.
just a number) or a data address space corresponding to a register. 
These often take just one clock cycle - e.g. `ADD R1, R2`. In indirect 
addressing, the value given is a data address space of internal SRAM,
corresponding to a byte of data with which the opcode is concerned.
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
instruction) are only 16-bits, and 16-bits are required to give an SRAM data
space address.

Some opcodes work with I/O registers, e.g. 'OUT PORTB, R17'. However the 
opcodes for IN and OUT instructions requires the IO register address space.
The same I/O register (e.g. PORTA) may have a different address in different
AVR microcontrollers. Therefore the macro `#include <avr/io.h>` is added to
the start of the assembly file which converts the registers (e.g. PORTA) to
I/O space addresses using the _SFR_IO_ADDR() macro. Note the file type must be
.S (capital S) so avr-gcc invokes the C pre-comiler even though the file type
is assembly. The AVR microcontroller used is given to the assembler with the 
`-mmcu=` option.

Toolchain used
--------------
I am using the avr-as assembler, not the popular windoes ATMEL Studio 
assembler. The syntax is very similar, but note a few differences:
 - use `lo8(0xabcd)` and `hi8()` instead of `low()` and `high()`
 - use `.byte` instead of `.db`
 - cannot store a string using `.byte`

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
Intel HEX format binary file created.

Using a Raspberry Pi as an AVR programmer
-----------------------------------------
Once the intel hex file is created, the EEPROM of the AVR microcontroller
needs to be flashed. Whilst dedicated programmers can be brought, it will
be done here using avrdude software with physical interfacing via RPi GPIO
pins.

Connect the RPi to the AVR microcontroller (via a breadboard):
 - AVR VCC to RPi 5 volt pin
 - AVR GND to RPi ground pin
 - AVR RESET to RPi GPIO #15
 - AVR SCK to RPi GPIO #24
 - AVR MOSI to RPi GPIO #23
 - AVR MISO to RPi GPIO #18

Installing avrdude (see prev) created a configuration file /etc/avrdude.conf.
Copy the contents of this file to new avrdude_gpio.conf. Append the following
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

Program the AVR microcontroller:
```
sudo avrdude -p atmega32 -C avrdude_gpio.conf -c pi_1 -v -U flask:w:myfile.hex:i
```

Note a usefull resource found on learn.adafruit.com.


