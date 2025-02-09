#!/bin/bash -e

#OPTS=--ieee=synopsis

OPTS=

ghdl -a ${OPTS} ../vhdl/sample_rate_converter_pkg.vhd
ghdl -a ${OPTS} ../vhdl/coeff_rom.vhd
ghdl -a ${OPTS} ../vhdl/sample_rate_converter.vhd
ghdl -a ${OPTS} sample_rate_converter_tb.vhd
ghdl -e ${OPTS} sample_rate_converter_tb
ghdl -r sample_rate_converter_tb --vcd="audio.vcd" --stop-time=1ms

if [ -z "$DISPLAY" ]; then
    echo Display not set, skipping gtkwave
else
    gtkwave audio.vcd sample_rate_converter.gtkw
fi
