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

  The minimum required number of taps, NTaps, is approximated by:

  NTaps =  Atten
          -------
          22 * Tw

  Note: For the polyphase implementation, NTaps needs to be a integer
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
  symmetric, so there are NTaps/2 unique coefficients with 16-bit or
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

In this section we consider the feasibility of a sharing a single
filter between all three sources.

Summarising the minimum filter requirements we arrived on above:

                L     M      Multiplies             NTaps
                          12KHz 15KHz 20KHz   12KHz 15KHz 20KHz
Music 5000 L   128   125     12    16    38    1536  2048  4864
Music 5000 R   128   125     12    16    38    1536  2048  4864
SN76489         24   125     57    76   171    1368  1824  4104
SID              6   125    228   304   682    1368  1824  4092
                            ---   ---   ---
                            309   412   929
                            ---   ---   ---

Considering the number of multiplies, the totals are all less than
1,000. So an implementation with a single physical multiplier would be
possible, with a system clock rate of 48MHz.

To share a single set of filter coefficients, NTaps would have to be
integer multiple of 128, 24 and 6. Anything that is a multiple of 384
(the LCM of 128, 24 and 6) would be suitable. More taps is, I think,
beneficial as it reduces the stop band attenuation.

It's interesting to consider how much we could achieve with one
multiplier and a pair of block RAMs. On the Gowin architecture, a
block RAM is 2048x9, so a pair of block RAMs gives a store of 2048x18
bits. This is a convenient size.

The block RAM is needed for filter coefficients and for sample
buffering. As the block RAM is dual port, one port could be used to
read the coefficients, and the other port to read/write the sample
buffer.

The filter coefficients are symmetric, so there are NTaps/2 values to
store. The sample buffering size matches the total number of
multiplies (as each multiply uses a different sample).

There is a spreadsheet (parameters.ods) that allows experimentation
with different choices here.

A NTaps value of 2688 (384*7) gives the highest utilisation of a 2048x18
block RAM:

  coefficient storage: 1344 words
            buffering:  602 words
                       ----
                       1946 words
                       ----

We can explore the noise / bandwidth trade off with a filter of this
size, using the following approximation:

NTaps =    Atten * Fsfilter
        --------------------
        22 * (Fstop - Fstart)

rearranging gives:

Fstart = Fstop - Atten * Fsfilter
                 ----------------
                    22 * NTaps

Substituting NTaps=2688, Fstop=24, Fsfilter=6000 gives:

Fstart = 24 - 0.1015 * Atten

This gives the following performance curve:

Atten:    Fstart:
  40dB    19.94KHz
  45dB    19.43KHz
  50dB    18.93KHz
  55dB    18.42KHz
  60dB    17.91KHz
  65dB    17.41KHz
  70dB    16.90KHz
  75dB    16.39KHz
  80dB    15.88KHz
  85dB    15.38KHz
  90dB    14.87KHz

The number of multiplies is 602.

That leave about 40% of the cycles free.

This allows a nice trade off between noise floor and bandwidth to be
made at simply by calculating the filter coefficients differently.

We can explore some larger block RAM sizes.

---------------------------------------------------------

Increasing the block RAM size to 3072 x 18 would allow NTaps = 4224.

This gives the following performance curve:

Atten:    Fstart:
  40dB    21.42KHz
  45dB    21.09KHz
  50dB    20.77KHz
  55dB    20.45KHz
  60dB    20.13KHz
  65dB    19.80KHz
  70dB    19.48KHz
  75dB    19.16KHz
  80dB    18.83KHz
  85dB    18.51KHz
  90dB    18.19KHz

The number of multiplies is 946.

That leaves about 5% of the cycles free.

---------------------------------------------------------

Increasing the block RAM size to 4096 x 18 would allow NTaps = 5376.

This gives the following performance curve:

Atten:    Fstart:
  40dB    21.97KHz
  45dB    21.72KHz
  50dB    21.46KHz
  55dB    21.21KHz
  60dB    20.96KHz
  65dB    20.70KHz
  70dB    20.45KHz
  75dB    20.20KHz
  80dB    19.94KHz
  85dB    19.69KHz
  90dB    19.43KHz

The number of multiplies is 1204.

That exceeds the number of available cycles, so two physical
multipliers would be needed.


Detailed Timing
===============

Assume everthing running from a single 48MHz system clock.

Output sample must be produced every 1000 cycles (i.e. @ 48KHz)

Input cycle is asnchronous to this:
     Music 5000 L input sample every 1024 cycles, min buffer is  21 words
     Music 5000 R input sample every 1024 cycles, min buffer is  21 words
     SN76489      input sample every  192 cycles, min buffer is 112 words
     SID          input sample every   48 cycles, min buffer is 448 words


There is a buffer for each port channel, the min (NTaps/L).

We round these up to the next power of two, for two reasons:
- so the input doesn't have to be phase locked to the output
- so the circular buffer pointer arithemtic is each

This uses 32+32+128+512 = 704 words, plus 1344 filter coefficients.

With the 1344 filter coefficients that packs exactly into 2048 words.

Each source needs a seperate read and write pointer.

The write pointer is the offset where the next input sample is to be
written. After writimg the sample, the pointer is incremented by one,
modulo the buffer size.

The read pointer is the offset of the most recent sample visible to
the channel filter. It's incremented at the end of the 48KHz cycle, by
an amount that depends on whether the filter index K has wrapped.

As a reminder, in the C code we have:
         // Updates k and m incrementally such that:
         //     k = (m * M) % L
         //     n = (m * M) / L
         k += M;
         while (k >= L) {
            k -= L;
            n++;
         }

In VHDL we use Inc2 if k has wrapped, otherwise Inc1.

                L     M     Inc1  Inc2
Music 5000     128   125    0     1
SN76489         24   125    5     6
SID              6   125    20    21

602 cycles are needed for multiplies; this uses both RAM ports:
- Port A reads the sample from the buffer
- Port B reads the filter coefficient from the

The order in which the filters are evaluated makes no difference, as
long as a the calculations are complete within the 1000 cycles.

State:

Init        acc1  = 0; outL = 0; outR = 0
Music5000L  acc1 += coeff0 * data @ rd offset  0
Music5000L  acc1 += coeff1 * data @ rd offset -1
            ...
Music5000L  acc1 += coeff20 * data @ rd offset -20
Scale       acc1 *= 20 (L)
Transfer    outL = acc1; acc1 = 0
Music5000R  acc1 += coeff0 * data @ rd offset  0
Music5000R  acc1 += coeff1 * data @ rd offset -1
            ...
Music5000R  acc1 += coeff20 * data @ rd offset -20
Scale       acc1 *= 20 (L)
Transfer    outR = acc1; acc1 = 0
SN76489     acc1 += coeff0 * data @ rd offset  0
SN76489     acc1 += coeff0 * data @ rd offset -1
            ...
SN76489     acc1 += coeff111 * data @ rd offset -111
Scale       acc1 *= 112
Transfer    outL += acc1; outR += acc1; acc1 = 0
SID         acc1 += coeff0 * data @ rd offset  0
SID         acc1 += coeff0 * data @ rd offset -1
            ...
SID         acc1 += coeff447 * data @ rd offset -447
Scale       acc1 *= 448
Transfer    outL += acc1; outR += acc1; acc1 = 0

This needs to be sequenced by a state machine, with appropriately
pipelined control signals to the DSP Multiply/Accumulate, which has
registered inputs and outputs.

In the event an input sample arrived, this will take priority and the
pipeline is stalled in it's current state.

---

References:

    Understanding Digital Signal Processing, Third Edition
    Richard G Lyons

    Crochiere, R. and Rabiner, L.
    "Decimation and Interpolation of Digital Signals-A Tutorial Review,"
    Proceedings of the IEEE, Vol. 69, No. 3, March 1981.
