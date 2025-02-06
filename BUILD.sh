#!/bin/bash


mkdir -p build/infinitewave

FILE=TestSignals.zip

cd build/infinitewave
if [ ! -f $FILE ]; then
    wget http://src.infinitewave.ca/TestSignals.zip
fi
unzip -u $FILE
cd -


gcc -DTEST_96000_44100 src/test.c src/tinywav.c -o build/test

suffix=float.wav
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

gcc -DTEST_46875_48000 src/test.c src/tinywav.c -o build/test

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

    ./build/test ${infile} ${outfile} ${channels} 1000
done
