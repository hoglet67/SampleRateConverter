#!/bin/bash

suffix=float.wav

EXTRA=-DTEST_VHDL

gcc $EXTRA -DTEST_250000_48000 src/test.c src/tinywav.c -o build/test

mkdir -p build/250000

for i in \
    Square_525Hz_6dB
do
    infile=tests/250000/${i}_${suffix}
    outfile=build/250000/${i}_${suffix}
    echo ${infile}
    channels=1

    if [ -f ${infile} ]; then
        ./build/test ${infile} ${outfile} ${channels} 1000
    else
        echo "   ...skipping as file ${infile} not present"
    fi

done

mkdir -p build/infinitewave

FILE=TestSignals.zip

cd build/infinitewave
if [ ! -f $FILE ]; then
    wget http://src.infinitewave.ca/TestSignals.zip
fi
unzip -u $FILE
cd -


gcc $EXTRA -DTEST_96000_44100 src/test.c src/tinywav.c -o build/test

for i in Pulses Swept Tone1kHz
do
    infile=build/infinitewave/${i}_${suffix}
    outfile=build/${i}_${suffix}
    echo ${infile}
    if [ "$i" == "Tone1kHz" ]; then
        channels=2
    else
        channels=1
    fi
    ./build/test ${infile} ${outfile} ${channels} 1000
done

gcc $EXTRA -DTEST_46875_48000 src/test.c src/tinywav.c -o build/test

mkdir -p build/46875

for i in \
    Sine_1KHz_0dB \
    Sine_10KHz_0dB \
    Sine_1KHz_60dB \
    Sine_10KHz_60dB \
    Square_1KHz_6dB \
    Square_10KHz_6dB \
    Swept \
    assault_iir
do
    infile=tests/46875/${i}_${suffix}
    outfile=build/46875/${i}_${suffix}
    echo ${infile}
    if [ "$i" == "assault_iir" ]; then
        channels=2
    else
        channels=1
    fi

    if [ -f ${infile} ]; then
        ./build/test ${infile} ${outfile} ${channels} 1000
    else
        echo "   ...skipping as file ${infile} not present"
    fi

done
