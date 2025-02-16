# Note: ending a line with a semicolon suppresses printing the result

pkg load signal

close all;
clear all;
#clf;

dB  = 84
L = 96
M = 125
Fsin = 62500
Fsimm1 = Fsin * L
Fsout = Fsimm1 / M

f1 = 18000
f2 = min(Fsin/2, Fsout/2)

delta_f = f2 - f1;

# Calculate minimum number of taps
N = dB * Fsimm1 / (22 * delta_f)

# Round up to the next multiple of L
N = L * ceil(N / L)

# Original version was dumb in lots of respects
# f =  [f1] / (Fsimm1 / 2)
#h c = fir1(N-1, f,'low');

# This uses FIR2 so we get a trasition band!
f = [0 (2*f1/Fsimm1) (2*f2/Fsimm1) 1]
a =  [1 1 0 0]
#hc = fir2(N-1, f, a);

# Current version using a kaiser window
hc = fir2(N-1, f, a, kaiser(N, 10));

freqz(hc,1,512,Fsimm1)

# Scale coefficients to cope with gain loss due to interpolation
#hc = hc * L;

# Set a fixed gain of 256. This is the largest value that,
# combined with an 8-bit volume, will comfortably fit in
# a 18-bit signed multiplier operand ( in scaling step)
hc = hc * 2^8;

hc_min = min(hc)
hc_max = max(hc)
hc_sum = sum(hc)

# Scale coefficients to occupy the full 18-bit precision:
# hc_min = -20582
# hc_max =  98544
hc = round(hc * 2^16);

# Log some stats
hc_min = min(hc)
hc_max = max(hc)
hc_sum = sum(hc)

# Save to a file
save hc.txt hc;
