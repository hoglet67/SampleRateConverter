# Note: ending a line with a semicolon suppresses printing the result

pkg load signal

close all;
clear all;
#clf;

dB  = 60
L = 147
M = 320
Fsin = 96000
Fsimm1 = Fsin * L
Fsout = Fsimm1 / M

f1 = 20000
f2 = min(Fsin/2, Fsout/2)

delta_f = f2 - f1;

# Calculate minimum number of taps
N = dB * Fsimm1 / (22 * delta_f)

# Round up to the next multiple of L
N = L * ceil(N / L)

# HACK REMOVE ME
# N = L * 3

# Calculate N tap FIR filter coefficients
f =  [f1] / (Fsimm1 / 2)
hc = fir1(N-1, f,'low');

freqz(hc,1,512,Fsimm1)

# Scale coefficients to cope with gain loss due to interpolation
hc = hc * L;

hc_min = min(hc)
hc_max = max(hc)
hc_sum = sum(hc)

# Scale coefficients to be represented as 16-bit signed integers
hc = round(hc * 2^15);

# Log some stats
hc_min = min(hc)
hc_max = max(hc)
hc_sum = sum(hc)

# Save to a file
save hc.txt hc;


