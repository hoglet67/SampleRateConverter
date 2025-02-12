#!/bin/bash -e

#OPTS=--ieee=synopsis

OPTS=

ghdl -a ${OPTS} ../../vhdl/sample_rate_converter_pkg.vhd
ghdl -a ${OPTS} ../../vhdl/buffer_ram.vhd
ghdl -a ${OPTS} ../../vhdl/coeff_rom.vhd
ghdl -a ${OPTS} ../../vhdl/sample_rate_converter.vhd
ghdl -a ${OPTS} sample_rate_converter_tb.vhd
ghdl -e ${OPTS} sample_rate_converter_tb
ghdl -r sample_rate_converter_tb --vcd="audio.vcd" --stop-time=3ms | tee audio.log
cut -d\) -f2- audio.log  | cut -c2- | awk '{print $1}' | nl > audio.plot
if [ -z "$DISPLAY" ]; then
    echo Display not set, skipping gtkwave
else
    gnuplot -e "plot 'audio.plot' with lp pt 7 ps 0.2" -p
    gtkwave audio.vcd sample_rate_converter.gtkw
fi
