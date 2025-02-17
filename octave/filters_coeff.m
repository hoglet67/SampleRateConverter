# Note: ending a line with a semicolon suppresses printing the result

pkg load signal

close all;
clear all;
#clf;


# Estimate N
#dB  = 84
#L = 96
#M = 125
#Fsin = 62500
#Fsimm1 = Fsin * L
#Fsout = Fsimm1 / M
#f1 = 18000
#f2 = min(Fsin/2, Fsout/2)
#delta_f = f2 - f1;
## Calculate minimum number of taps
#N = dB * Fsimm1 / (22 * delta_f)
## Round up to the next multiple of L
#N = L * ceil(N / L)


Fsimm1 = 6000000

# For reference, here's the original filter
fref = 18000
nref = 3840
hcref = fir1(nref-1, [ 2*fref/Fsimm1 ] ,'low');

# start of transition band
f1 = 16000

# end of transition band
f2 = 24000

# pass band deviation
# (this seems to have no effect)
att1 = db2mag(-60)

# stop band deviation
# manually chosen with 16K/24K transition so kaiserord produces n=3840
att2 = db2mag(-81.5)

# Calculate a kaiser window FIR filter than meets these needs
[n,Wn,beta,ftype] = kaiserord([f1 f2], [1 0],[att1 att2], Fsimm1)

# Output the transition frequency
Wn * Fsimm1 / 2

# Calculate the filter using FIR1
hc = fir1(n-1, Wn, ftype, kaiser(n, beta));

# Graph the filter
# freqz(hc, 1, 15000:50:30000, Fsimm1)

[h{1},w{1}] = freqz(hcref, 1, 15000:50:30000, Fsimm1);
[h{2},w{2}] = freqz(hc, 1, 15000:50:30000, Fsimm1);

figure
subplot(2,1,1)
hold on
for k = 1:2
    plot(w{k},20*log10(abs(h{k})))
end
hold off
grid
subplot(2,1,2)
hold on
for k = 1:2
    plot(w{k},unwrap(angle(h{k})))
end
hold off
grid


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
