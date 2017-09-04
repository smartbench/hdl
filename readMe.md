# Smartbench - Hdl

This repository is part of the Smartbench project (https://github.com/smartbench), and contains the FPGA related files.
That includes the verilog files to configure the FPGA, with their respective testbenchs.

## Tools

### FPGA Tools (iCEstorm flow)
* Synthesis: yosys
* Place and Route: Arachne-PNR
* Programming, time analysis, etc: IceStorm Tools (icepack, icebox, iceprog, icetime, chip databases)
    
### Testing Tools
* Verilog simulator: Icarus Verilog
* Python testbenchs: Cocotb
* Waveforms visualization: GTKwave
        
## Installing tools

### iCEstorm flow
* Sources
    * icestorm - https://github.com/cliffordwolf/icestorm
    * yosys - https://github.com/cliffordwolf/yosys.git
    * arachne-pnr - https://github.com/cseed/arachne-pnr
* Dependencies

        sudo dnf install make automake gcc gcc-c++ kernel-devel clang bison \
                 flex readline-devel gawk tcl-devel libffi-devel git mercurial \
                 graphviz python-xdot pkgconfig python python3 libftdi-devel
* Install (for each tool)

        git clone <source>
        cd <path>
        make -j$(nproc)
        sudo make install
* Documentation
    [iCEstorm workflow](http://www.clifford.at/icestorm/)
    [yosys](http://www.clifford.at/yosys/)

### Icarus Verilog
* Source
    https://github.com/steveicarus/iverilog
* Dependencies
    - GNU Make
    - ISO C++ Compiler
    - Bison and Flex
    - gperf 2.7
    - readline 4.2
    - termcap
* Install

        ./autoconf.sh
        ./configure
        make
        sudo make install

### Cocotb
* Source
    https://github.com/potentialventures/cocotb
* Dependencies
    * Python 2.6+
    * Python-dev packages
    * GCC and associated development packages
    * GNU Make
    * A Verilog simulator
    ```
    sudo yum install gcc gcc-c++ libstdc++-devel swig python-devel
    # for building 32bit python on 64 bit systems
    sudo yum install glibc.i686 glibc-devel.i386 libgcc.i686 libstdc++-devel.i686
    ```
* Enviroment variable
    ```
    export COCOTB=<path>
    # add to /etc/enviroment to save it permanently
    ```

### Gtkwave
* Install
    ```
    # installing directly from repo
    sudo yum install gtkwave.x86_64
    ```
## Running the tests
There is a folder for each module, containing the test files.
```
    /hdl/modules/<module>/test_<name>/
```
Tests are executed by running ```Make``` in that folder.
The debug results are printed in the command prompt, and the waveform stored in the file ```waveform.vcd```.
To visualize the waveform, open that file with ```GTKwave```.

## Authors

* **Nahuel Carducci** - *Developer* - [url](https://github.com/...)
* **Andres Demski** - *Developer* - [url](https://github.com/...)
* **Ariel Kukulanski** - *Developer* - [url](https://github.com/...)
* **Ivan Paunovic** - *Developer* - [url](https://github.com/...)

See also the list of [contributors](https://github.com/smartbench/hdl/contributors) who participated in this project.

## License

This project is licensed under the (undefined yet) License

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc

