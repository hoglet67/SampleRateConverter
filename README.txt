Introduction
============

This repository contains files related to hoglet's experiments with
sample rate conversion using polyphase filters.

The plan is to develop a VHDL implementation than can be used in
BeebFPGA to convert the following sources:

Music5000: 46.875KHz -> 48KHz
 SN764789:    250KHz -> 48KHz
      SID:      1MHz -> 48KHz

The 48KHz output sample rate is driven by the needs of HDMI.

Polyphase filters
=================

Some notes on polyphase filters for sample rate conversion

- sample rate conversion involves three steps:
  1. expansion by a factor of L by zero stuffing
  2. low pas filtering to eliminate spectral images
  3. decimation by a factor of M by dropping samples

- these are an efficient implementation pattern for low pass FIR
  filters used in sample rate conversion

- they avoid unnecessary work, such as multiplication by zero and
  calculating output values that will be dropped.

- the filter coefficients are calculated using the same software that
  designs normal FIR filters (e.g. Martel, GNU Octave, ..)

- the number of taps is proportional to the acceptable stop band
  attenuation (Atten, expressed in dBs). The stop band attenuation is
  the main contributor to the noise floor of the output.

- the number of taps is inversely proportional to the width of the
  filter transition band (Tw), expressed as a proportion of the filter
  sample rate.

  Tw = Fstop - Fstart
       -------------
         Fsfilter

  Fsfilter = Fsin * L = Fsout * M

  Fstart = start of the transition band; this is driven from the
  required bandwidth of the overall resampler. So at most 20KHz, but
  for our application it could be a bit less.

  Fstop = end of the transition band; this driven by the need to avoid
  aliasing, and is the minimum of Fsin/2 and Fsout/2.

  The minimum required number of taps, Ntaps, is approximated by:

  Ntaps =  Atten
          -------
          22 * Tw

  Note: For the polyphase implementation, Ntaps needs to be a integer
  multiple of L.

For now, we'll assume Atten = 60dB, then come back to this later.

In all cases, we'll assume Fstop = 24KHz.

Looking at each of our sources in turn:

Music 5000
==========

46.875KHz -> 48KHz

Interpolate by L=128, decimate by M=125, giving Fsfilter of 6MHz.

For Fstart=12KHz, a single stage polyphase filter would need need 1536
taps (=128x38). Each 48KHz output sample requires 12 multiplies.

For Fstart=15KHz, a single stage polyphase filter would need need 2048
taps (=128x16). Each 48KHz output sample requires 16 multiplies.

For Fstart=20KHz, a single stage polyphase filter would need need 4864
taps (=128x38). Each 48KHz output sample requires 38 multiplies.

Note, the Music 5000 includes a 3.2KHz 2nd order low pass filter.

These values assume Fstop of Fsin/2 (23.4375KHz) rather than Fsout/2
(24KHz), hence this filter is a bit longer than the others. Given the
Music 5000 is already very band limits, the larger value of Fstop would
be fine I think.

SN76489
=======

250KHz -> 48KHz

Interpolate by L=24, decimate by M=125, giving Fsfilter of 6MHz.

For Fstart=12KHz, a single stage polyphase filter would need need 1368
taps (=24x57). Each 48KHz output sample requires 57 multiplies.

For Fstart=15KHz, a single stage polyphase filter would need need 1824
taps (=24x76). Each 48KHz output sample requires 76 multiplies.

For Fstart=20KHz, a single stage polyphase filter would need need 4104
taps (=24x171). Each 48KHz output sample requires 171 multiplies.

Note, the Beeb includes a 7.2KHz second order low pass filter (IC17a).

SID
===

1MHz -> 48KHz

For Fstart=12KHz, a single stage polyphase filter would need need 1368
taps (=6x228). Each 48KHz output sample requires 228 multiplies.

For Fstart=15KHz, a single stage polyphase filter would need need 1824
taps (=6x304). Each 48KHz output sample requires 304 multiplies.

For Fstart=20KHz, a single stage polyphase filter would need need 4092
taps (=6x682). Each 48KHz output sample requires 682 multiplies.

Note, the highest frequency tone that can be produced is 3.9KHz. This
can be a square wave. The audio bandwidth depends on the how the
interface filter is used.

FPGA Implementation Considerations
==================================

In implementing this sample rate converter in an FPGA we need to
consider:

- the requirements for filter coefficient storage. The filter is
  symmetric, so there are Ntaps/2 unique coefficients with 16-bit or
  18-bit precision. A 2KB block RAM can store 2048 coefficients.

- the requirements for input buffering. The filter needs to store
  NTaps/L samples (the length of each sub-filter), for each channel
  being processed.

- the number of multiplies per output sample. For a system clock of
  48MHz, and an output sample rate of 48KHz there at 1,000 system
  cycles available to calculate each output sample. If the number of
  multiplies is less than this, then a single physical multiplier will
  suffice.

- whether it's beneficial to spilt the sample rate conversion into two
  (or more) steps. This will certainly reduce the number of
  multiplies, but may complicate the implementation. Perversely, It may
  also increase the number of block RAMs used, as it might be
  difficult to share a block RAM between two polyphase filters
  operating independently.

- whether a single filter can be shared by all three sources. This
  might be well possible. One consideration is that iterpolating by L
  (by zero stuffing) results in a gain of 1/L. And L is different for
  each source. If this is compensated for by simply scaling the filter
  coefficients, then the filter for each source will be different. An
  alternative is to arrange for each 48KHz output sample to be
  multiplied by an appropriate L before mixing (summing) them.

- if a source is stereo, then this doubles the number of multiplies.

Shared filter implementation
============================

Summarising the above:

                   Multiples               NTaps          L     M
               12KHz 15KHz 20KHz     12KHz 15KHz 20KHz
Music 5000 L    12    16    38       1536  2048  4864    128   125
Music 5000 R    12    16    38       1536  2048  4864    128   125
SN67489         57    76   171       1368  1824  4104     24   125
SID            228   304   682       1368  1824  4092      6   125
               ---   ---   ---                           ---
               309   412   929                           286
               ---   ---   ---                           ---

The total of the L column gives the number of samples storage
required. If each is rounded up to the next power of two, it makes the
pointer arithmetic easy. That would be 128+128+32+8=296.

Considering the number of multiplies, the totals are all less than
1,000. So an implementation with a single physical multiplier would be
possible.

To share a single set of filter coefficients, Ntaps would have to be
integer multiple of 128, 24 and 6. Anything that is a multiple of 384
would be suitable. More taps is, I think, beneficial as it reduces the
stop band attenuation.

It's interesting to consider how much we could achieve with one
multiplier and a pair of block RAMs.

On the Gowin architecture, a block RAM is 2048x9, so a pair of block
RAMs gives a store of 2048x18 bits.

This would be split between input storage (296 words) and coefficient
storage (1752 words). As the filters are symmetric, that allows a
filter of NTaps = 3504 (1752 * 2). The nearest value that is a
multiple of 384 is Ntaps = 3456 (384 * 9).

This number of taps would allow a bandwidth of:
- 19.2KHz with stop band attenuation of 60dB

Ntaps =    Atten * Fsfilter
        --------------------
        22 * (Fstop - Fstart)

Re-arranging this and substituting Ntaps=3456, Fstop=24, Fsfilter=6000 gives:

Fstart = 24 - 0.0789 * Atten

Atten:    Fstart:
 40dB  20.844KHz
 50dB  20.055KHz
 60dB  19.266KHz
 70dB  18.477KHz
 80dB  17.688KHz
 90dB  16.899KHz

This allows a nice trade off between noise floor and bandwidth to be
made at simply by calculating the filter coefficients differently.

---

References:

    Understanding Digital Signal Processing, Third Edition
    Richard G Lyons

    Crochiere, R. and Rabiner, L.
    "Decimation and Interpolation of Digital Signals-A Tutorial Review,"
    Proceedings of the IEEE, Vol. 69, No. 3, March 1981.
