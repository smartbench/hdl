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

Useful commands:
# Program ROM using fake adc
    make prog DEF=FAKE_ADC
