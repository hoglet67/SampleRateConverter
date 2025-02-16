#include <stdio.h>
#include <stdlib.h>
#include "tinywav.h"

//#define TEST_46875_48000
//#define TEST_250000_48000
//#define TEST_96000_44100

#if defined(TEST_46875_48000)

// LCM is 6MHz

#ifdef VHDL
#include "coefficients_vhdl2.h"
#else
#include "coefficients_46875_48000_60.h"
#endif

//#include "coefficients_46875_48000_extended.h"
//#include "coefficients_46875_48000_truncated.h"

#define               L   128
#define               M   125
#define  IN_SAMPLE_RATE 46875
#define OUT_SAMPLE_RATE 48000

#elif defined(TEST_250000_48000)

// LCM is 6MHz

#ifdef VHDL
#include "coefficients_vhdl2.h"
#else
#include "coefficients_250000_48000_60.h"
#endif

#define               L    24
#define               M   125
#define  IN_SAMPLE_RATE 250000
#define OUT_SAMPLE_RATE 48000

#elif defined(TEST_96000_44100)

// LCM is 14.112MHZ

#ifdef VHDL
#include "coefficients_vhdl2.h"
#else
#include "coefficients_96000_44100_60.h"
#endif

#define               L   147
#define               M   320
#define  IN_SAMPLE_RATE 96000
#define OUT_SAMPLE_RATE 44100

#endif

// Wav reading/writing code
#define    MAX_CHANNELS     2
#define      BLOCK_SIZE  1024

// Integer scale factor of filter coefficients
#define          HSCALE 32768

// Integer scale factor of wav file data
#define          WSCALE 32768

static int read_wav
(
    char *filename,
    int num_samples,
    int stereo,
    float *left,
    float *right)
{
   int n = 0;
   float buffer[MAX_CHANNELS * BLOCK_SIZE];
   TinyWav tw;
   int ret = tinywav_open_read(&tw, filename, TW_INTERLEAVED);
   if (ret != 0) {
      printf("tinywav_open_read returned error %d\n", ret);
      exit(ret);
   }
   while (1) {
      int ret = tinywav_read_f(&tw, buffer, BLOCK_SIZE);
      if (ret < 0) {
         printf("tinywav_read_r returned error %d\n", ret);
         exit(ret);
      }
      float *bp = buffer;
      if (ret == 0) {
         tinywav_close_read(&tw);
         return n;
      }
      while (ret > 0 && n < num_samples) {
         if (*bp < -1.0 || *bp > 1.0) {
            printf("sample out of range: %f\n", *bp);
            exit(1);
         }
         *left++ = *bp++;
         if (stereo) {
            *right++ = *bp++;
         }
         ret--;
         n++;
      }
      if (n >= num_samples) {
         tinywav_close_read(&tw);
         return n;
      }
   }
}

static int write_wav
(
    char *filename,
    int num_samples,
    int stereo,
    float *left,
    float *right)
{

   TinyWav tw;
   float buffer[BLOCK_SIZE * MAX_CHANNELS];
   tinywav_open_write(&tw, stereo ? 2 : 1, OUT_SAMPLE_RATE, TW_FLOAT32, TW_INTERLEAVED, filename);

   for (int i = 0; i < num_samples / BLOCK_SIZE; i++) {
      // NOTE: samples are always expected in float32 format,
      // regardless of file sample format
      float *bp = buffer;
      for (int j = 0; j < BLOCK_SIZE; j++) {
         *bp++ = *left++;
         if (stereo) {
            *bp++ = *right++;
         }
      }
      tinywav_write_f(&tw, buffer, BLOCK_SIZE);
   }

tinywav_close_write(&tw);
}

int main(int argc, char **argv) {
   int t = 0;
   if (argc < 4) {
      fprintf(stderr, "usage %s: infile outfile num_channel [ seconds ]\n", argv[0]);
   }
   char *infile = argv[1];
   char *outfile = argv[2];
   int stereo = (atoi(argv[3]) == 2);
   if (argc > 4) {
      t = atoi(argv[4]);
   }
   if (t <= 0) {
      t = 10;
   }
   int num_in_samples = t * IN_SAMPLE_RATE;
   float *ileft = malloc(num_in_samples * sizeof(float));
   float *iright = malloc(num_in_samples * sizeof(float));

   // Read in the WAV file at the input sample rate
   num_in_samples = read_wav(infile, num_in_samples, stereo, ileft, iright);

   int num_out_samples = num_in_samples * L / M;

   float *oleft = malloc(num_out_samples * sizeof(float));
   float *oright = malloc(num_out_samples * sizeof(float));

   long min_in = 0;
   long max_in = 0;
   long min_out = 0;
   long max_out = 0;

   for (int c = 0; c < 2; c++) {

      int m = 0;
      float *din = c ? iright : ileft;
      float *dout = c ? oright : oleft;

      // The sub filter to use for the mth sample, updated incrementally so
      //  k = (m * M) % L
      int k = 0;

      // The most recent input sample to use, updated incrementally so
      //  n = (m * M) / L
      int n = 0;

      while (m < num_out_samples) {

         // Calculate the mth output sample
         long sum = 0;
         for (int p = 0; p < NTAPS / L; p++) {
            long d = (n - p) <= 0 ? 0 : ((long) (din[n - p] * WSCALE));
            if (d < min_in) {
               min_in = d;
            }
            if (d > max_in) {
               max_in = d;
            }
            // Do the calculation in integer with a scale factor
            sum += d * hc[p * L + k];
         }
#ifdef TEST_VHDL
         // Fudge factor for the additional scale in the VHDL version
         sum *= L;
         sum >>= 24;
#else
         sum /= HSCALE;
#endif
         if (sum < min_out) {
            min_out = sum;
         }
         if (sum > max_out) {
            max_out = sum;
         }
         dout[m++] = ((float) sum) / (float) WSCALE;

         // Updates k and m incrementally such that:
         //     k = (m * M) % L
         //     n = (m * M) / L

         k += M % L;
         if (k >= L) {
            k -= L;
            n += (M / L) + 1;
         } else {
            n += (M / L);
         }
         /* k += M; */
         /* while (k >= L) { */
         /*    k -= L; */
         /*    n ++; */
         /* } */
         //dout[m++] = din[n]; // very crude resampling
      }
   }

   printf("min_in  = %ld\n", min_in);
   printf("max_in  = %ld\n", max_in);
   printf("min_out = %ld\n", min_out);
   printf("max_out = %ld\n", max_out);

   // Write out the WAV file at the output sample rate
   write_wav(outfile, num_out_samples, stereo, oleft, oright);

   return 0;
}
