## Smartbench
Smartbench is a project with the objective of providing low cost, open source and open hardware implementations of instruments for electronic.
The main target of this project are students of and hobbyist of electronics that can't afford (or don't want to) professional equipment, but would like to own the basic instruments.

## License


## Current situation
(05/03/2018) Today, there is a prototipe of what we call the "mainboard".
The mainboard is a digital oscilloscope based on an FPGA, with an available connector for future expansions.
The main features of the oscilloscope are:
- Two channels with 20MSPS each
- 5MHz cut-off frequency of the analog front-end
- Input Voltage between -25V and 25V
- DC / AC coupling
- Trigger modes: normal, auto, single shot
- Voltage scales: 10 mV/div to 5 V/div, with sequence 1,2,5,10,...
- Timebase: {100 nsec/div to 1 sec/div, with sequence 1,2,5,10,...

## Mainboard
The mainboard sources are split in three parts:
- Hardware (KiCad PCB Schematic, fab. files)
    https://github.com/smartbench/mainboard.git
- FPGA Firmware (Verilog)
    https://github.com/smartbench/hdl.git
- Software (Python)
    https://github.com/smartbench/software.git

# Smartbench - Firmware

The HDL loaded to the FPGA. The HDL used is Verilog, and the FPGA is a Lattice iCE40HX4K. The work flow consists on synthesis, place and route, and program the FPGA. The tools for that are open source, credits to Clifford.

## Installing the framework

The tools used for synthetize, place and route and load to the FPGA are well described in
    http://www.clifford.at/icestorm/
    https://github.com/cliffordwolf/yosys.git
    https://github.com/cseed/arachne-pnr
    https://github.com/cliffordwolf/icestorm.git
    
## Developers
- Nahuel Carducci - https://github.com/nahuel-cci
- Andres Demski - https://github.com/andresdemski
- Ariel Kukulanski - https://github.com/akukulanski
- Ivan Paunovic - https://github.com/ivanpauno
