
About the project:
    This repository is part of the Smartbench project (https://github.com/smartbench), and contains the FPGA related files.
    That includes the verilog files to configure the FPGA, with their respective testbenchs.

The following tools are used for development:

    FPGA Tools: (iCEstorm flow)
        Synthesis: yosys
        Place and Route: Arachne-PNR
        Programming, time analysis, etc: IceStorm Tools (icepack, icebox, iceprog, icetime, chip databases)
        
    Testing Tools:
        Verilog simulator: Icarus Verilog
        Python testbenchs: Cocotb
        Waveforms visualization: GTKwave

iCEstorm flow:
    Sources:
        https://github.com/cliffordwolf/icestorm
        https://github.com/cliffordwolf/yosys.git
        https://github.com/cseed/arachne-pnr
    Dependencies:
        sudo dnf install make automake gcc gcc-c++ kernel-devel clang bison \
                 flex readline-devel gawk tcl-devel libffi-devel git mercurial \
                 graphviz python-xdot pkgconfig python python3 libftdi-devel
    Install: (for each tool)
        git clone <source>
        cd <path>
        make -j$(nproc)
        sudo make install
    Documentation:
        http://www.clifford.at/icestorm/
        http://www.clifford.at/yosys/


Icarus Verilog
    Source: https://github.com/steveicarus/iverilog
    Dependencies:
        GNU Make
        ISO C++ Compiler
        Bison and Flex
        gperf 2.7
        readline 4.2
        termcap
    Install:
        ./autoconf.sh
        ./configure
        make
        sudo make install

Cocotb
    Source:
        https://github.com/potentialventures/cocotb
    Dependencies: 
        Python 2.6+
        Python-dev packages
        GCC and associated development packages
        GNU Make
        A Verilog simulator
        sudo yum install gcc gcc-c++ libstdc++-devel swig python-devel
        # for building 32bit python on 64 bit systems
        sudo yum install glibc.i686 glibc-devel.i386 libgcc.i686 libstdc++-devel.i686
    Before using:
        export COCOTB=<path>

Gtkwave:
    Install: # installing directly from repo
        sudo yum install gtkwave.x86_64
