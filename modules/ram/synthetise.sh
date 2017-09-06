# Before (separated modules for RAM and controller)
# yosys -p "synth_ice40 -blif tmp.blif -top ram_interface_2" ram_interface_2.v SB_RAM512x8.v

# After (unified module for RAM and controller)
yosys -p "synth_ice40 -blif tmp.blif -top ram_controller" ram_controller.v
