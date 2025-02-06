This repository contains files related to hoglet's experiments with
sample rate conversion using polyphase filters.

The plan is to develop a VHDL implementation than can be used in
BeebFPGA to convert the following sources:

Music5000: 46.875KHz -> 48KHz
 SN764789:    250KHz -> 48KHz
      SID:      1MHz -> 48KHz

References:

    Understanding Digital Signal Processing, Third Edition
    Richard G Lyons

    Crochiere, R. and Rabiner, L.
    "Decimation and Interpolation of Digital Signals-A Tutorial Review,"
    Proceedings of the IEEE, Vol. 69, No. 3, March 1981.
