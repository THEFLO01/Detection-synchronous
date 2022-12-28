TOPLEVEL_LANG ?= vhdl
SIM = ghdl

PWD=$(shell pwd)
WPWD=$(shell pwd)

PLUSARGS=--vcdgz=$(WPWD)/sim_build/waveform.vcdgz --wave=$(WPWD)/sim_build/waveform.ghw

VHDL_SOURCES =/home/florian/tools/oscimpDigital/fpga_ip/nco_counter/hdl/nco_counter.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/firComplex/hdl/firComplex_proc.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/firComplex/hdl/firComplex_top.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/firComplex/hdl/firComplex_ram.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/mixer_sin/hdl/mixer_sin.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/mixer_sin/hdl/mixer_redim.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/nco_counter/hdl/nco_counter_logic.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/nco_counter/hdl/nco_counter_synchronizer_bit.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/nco_counter/hdl/wb_nco_counter.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/shifterComplex_dyn/hdl/shifterComplex_dyn_logic.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/shifterComplex_dyn/hdl/shifterComplex_dyn_comm.vhd \
    /home/florian/tools/oscimpDigital/fpga_ip/shifterComplex_dyn/hdl/shifterComplex_dyn.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/shifterReal_dyn/hdl/shifterReal_dyn_logic.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/shifterReal_dyn/hdl/shifterReal_dyn_comm.vhd \
    /home/florian/tools/oscimpDigital/fpga_ip/shifterReal_dyn/hdl/shifterReal_dyn.vhd \
    /home/florian/tools/oscimpDigital/fpga_ip/pidv3_axi/hdl/pidv3_axi.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/pidv3_axi/hdl/pidv3_axi_logic.vhd \
	/home/florian/tools/oscimpDigital/fpga_ip/shifterReal/hdl/shifterReal.vhd
	
	
VHDL_SOURCES +=/home/florian/tools/simulation/simulation.vhd

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=simulation
# MODULE is the name of the Python test file:
MODULE=simulation_python


include $(shell cocotb-config --makefiles)/Makefile.sim

view:
	gtkwave -a top_firReal.gtkw sim_build/waveform.ghw

