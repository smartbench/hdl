
By default, the synthesis, place and route and programming settings are for
the mainboard rev1 (see https://github.com/smartbench/mainboard).

To work with the Lattice iCE40-HX8K Breakout Board, you can specify it with
    BOARD = breakout
The default interface is uart (INT=uart).
To work with a high speed interface (ft245), you can specify
    INT=ft245.
This interface requires a modification of the board, connecting a few
unused pins of the fpga to some pins in the FT2232H (see .pcf file and
FT2232H's datasheet to know how to connect).

In the breakout board, you can choose to program the flash memory or to load
the configuration directly to the CRAM, by changing a few jumpers. Use the
appropiate instruction of this Makefile in each case (prog / load-cram)

Synthesis can be done with a "fake adc" for testing. The fake signal can be a
sine wave, defining:
    DEF=FAKE_ADC
or a counter, defining:
    DEF="FAKE_ADC FAKE_ADC_ALT"

Examples:
    # Synthesis:
    make syn
    make syn DEF=FAKE_ADC

    # Place and Route:
    make pnr

    # Pack:
    make pack

    # Program Flash:
    make prog
    make prog DEF=FAKE_ADC BOARD=breakout INT=uart

    # Configure CRAM:
    make load-cram
