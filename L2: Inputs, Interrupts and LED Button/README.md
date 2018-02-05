Lesson 2: Inputs and Interrupts
===============================

This lesson covers:
 - How to detect when a GPIO pin is high with while loops
 - How to detect when a GPIO pin is high with interrupts
 - How to add a button that toggles the LEDs state

Detecting Inputs with While Loops
---------------------------------

In the last lesson we covered controlling MCU pins using the General I/O 
Registers DDRx, PORTx and PINx. These were used to drive a potential difference
from PORTA0 ("drive it _high_") and power on an LED.

In this lesson we will connect an input from +5V power source to PORTB2 (a
different port could equally have been chosen - the reason PORTB2 specifically
was used will be revealed later). This will be controlled by a button. When the
button is held down, current will flow to PORTB2. We will write software such 
that this causes the LED, connected to PORTA0 from lesson 1, to turn on.

The schematic is shown below. (See 'L2-Circuit-Diagram-LED-Button.png')

![L2 circuit diagram](L2-Circuit-Diagram-LED-Button.png)

Extending lesson one, controlling the LED with a button could be used with a
while loop to continualy check for the status of PORTB2, and drive PORTA0
accordingly. This is shown by the following main function.

```
main:
    ldi r16, 0x01                  ; Set bit 0 of r16 to 1 (output in DDR)
    out _SFR_IO_ADDR(DDRA), r16    ; Pin 0 of Port A configured as output
    ldi r18, 0x00                  ; Set bit 2 of r18 to 0 (input in DDR)
    out _SFR_IO_ADDR(DDRB), r18    ; Pin 2 of Port B configured as input

loop:
    in r17, _SFR_IO_ADDR(PINB)     ; Load status of Port B pins to r17
    andi r17, 0x02                 ; Isolate bit 2 of r17
    cpi r17, 0x02                  ; Compare r17 with immediate 0x02
    brne btn_up                    ; Jump to 'btn_up' label if bit 2 in r17 not
                                   ; set (i.e. button not depressed)

btn_down:                          ; Code only executed if button pressed
    out _SFR_IO_ADDR(PORTA), r16   ; 5V output from Port A pin 0 - LED turns on
    rjmp loop                      ; Return to start of loop

btn_up:                            ; Code only executed if button not pressed
    out _SFR_IO_ADDR(PORTA), r18   ; No output from Port A pin 0 - LED turns off
    rjmp loop                      ; Return to start of loop
```

However, this method requires the input to be continually tested for on a loop,
preventing anything else from being done while we wait form the button to be
depressed. A more clever way of detecting the button can thus be achieved using
interrupts. Before we can do this, some more theory must be covered.

A new register - SREG - Theory pt. 2
------------------------------------

In lesson one a number of atmega32 registers were discussed:

 - General Purpose Registers R0-R31 (8-bits wide)
 - 16-bit registers X (R26+R27), Y (R28+R29) and Z (R30+R31) for indirect 
   addressing
 - I/O Registers DDRx, PORTx and PINx for manipulating MCU pins
 - Instruction Register (IR) holds the instruction currently being executed
   (16-bits wide)
 - Program Counter (PC) where the address fo the next instruction to be executed
   (and thus loaded into IR) is stored (16-bits wide)

A special register not yet discussed is the Status Register (SREG). This fills
a similar purpose to the EFLAGS register in x86 CPUs. SREG is 8-bits wide, with
each bit giving the status of a particular characteristic of the MCU. Bits 0-5
are set as a result of arthimetic operations such as CP (compare) and ADD.

 - Bit 7 - I - Global Interrupt Enable        - Interrupts enabled if 1 (covered later)
 - Bit 6 - T - Copy Storage                   - Used as source/ destination for bit
                                                operated on by BLD/ BST instructions
 - Bit 5 - H - Half Carry Flag                - Set if half carry occured in arithmetic
                                                operation. This is when lower nibble
                                                values manipulation affects higher 
                                                nibble value of result. Used with 
                                                packed BCD. Rare.
 - Bit 4 - S - Sign Flag                      - S = N xor V. Set if result of 
                                                arithmetic operation was negative.
 - Bit 3 - V - Two's Complement Overflow Flag - Set if arithmetic operation
                                                changes most significant bit
                                                (indicating sign in two's
                                                complement) due to overflow.
 - Bit 2 - N - Negative flag                  - Set to most significant bit
                                                of arithmetic or logic operation.
                                                Indicates negative result (unless
                                                V set).
 - Bit 1 - Z - Zero flag                      - Indicates zero result in arithmetic
                                                or logic operation.
 - Bit 0 - C - Carry flag                     - Indicates carry in arithmetic or 
                                                logic operation. Possible if adding
                                                two values of same sign or subtracting
                                                two values of opposite sign.

Regarding the above code sample, a use of SREG is seen. In 'loop', `cpi r17, 0x02`
compares the value in R17 with the immediate 0x02 by performing the arithmetic
operation `R17 - 0x02`. If the button is depressed, R17 will hold the value 0x02
and so the result of the operation will be 0. This sets the Z flag of SREG to 1,
which is detected by BRNE instruction.

Regarding arithmetic operations, the main flag to understand is the C flag. This
can be used to perform arithmetic with higher presicion values (>8-bits). In the
following example 16-bit value R1:R0 is added to 16-bit value R3:R2. Note that 
the lower bytes are added first with ADD instruction. If a carry occurs on the
most significant bit of the smaller byte, it can be added to the least 
significant bit of the larger byte.

```
add r2, r0 ; Add low byte
adc r3, r1 ; Add with carry high byte
```

Note that INC and DEC instructions do not affect the carry byte. This is so that
when used to loop on arithmetic performed with higher precision values, the C
flag is preserved for use with the next iteration.

The other arithmetic / logic flags (H, S, V, N, Z) do not generally need to be
worried about directly, and are instead indirectly used with branching 
instructions. However H must be utilised manually if using packed Binary coded
Decimal (BCD), as AVR has no instructions for BCD arithmetic (unlike x86).
Fortunately this is an uncommon problem.

Again, it would be useful to review the Instruction Set Summary linked in the
main README.

Interrupts - Theory pt. 3
-------------------------


