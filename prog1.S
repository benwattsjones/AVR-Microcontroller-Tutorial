; #define __SFR_OFFSET 0
#include <avr/io.h>

.global main

main:
    ldi r16, 0x01   ; Set first bit of r16
    out _SFR_IO_ADDR(DDRA), r16   ; Pin 0 of Port A is configured as an output
    out _SFR_IO_ADDR(PORTA), r16  ; 5V output from Port A output pins

_end:
    rjmp _end

