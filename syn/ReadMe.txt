Readme.txt

Synthesis:
    make syn

Place and Route:
    make pnr

Pack:
    make pack

Program Flash:
    make prog

Configure CRAM:
    make load-cram


Top level file should be in ../top/
PCF file should be in ./

To change the top level, make TOP=<name_without_extension>
The pcf file should have the same name as the top level file.

To synthetise with a fake adc (testing purpose until having the mainboard),
there are two alternatives:

a) loads a signal contained in the file 'rom.hex' into a ROM. To choose this one,
only FAKE_ADC has to be defines.

b) a simple counter. To choose this one, FAKE_ADC and FAKE_ADC_ALT have to be defined.
    The defines are added as parameters in the Makefile.
    Examples:
        make syn DEF=FAKE_ADC
        make syn DEF="FAKE_ADC FAKE_ADC_ALT"

    To check if the fake adc is correctly set, you can do:
        make syn DEF=FAKE_ADC | grep "FAKE_ADC ON"

By default, ft245 interface is used.
To force the use of a specific interface:
    FT245:
        make (syn/prog/load-cram/etc.) INT=ft245
    UART:
        make (syn/prog/load-cram/etc.) INT=uart

Common instructions:
# load cram with ft245 interface and fake adc
    make load-cram DEF=FAKE_ADC INT=ft245

# load cram with uart interface and fake adc
    make load-cram DEF=FAKE_ADC INT=uart

# load cram with ft245 interface and real adc
    make load-cram INT=ft245

# load cram with uart interface and real adc
    make load-cram INT=uart
