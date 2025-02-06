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
    ./build/test ${infile} ${outfile} 100
done
