#include <stdio.h>
#include <stdlib.h>
#include "tinywav.h"

//#define TEST_46875_48000

//#define TEST_96000_44100

#if defined(TEST_46875_48000)

// LCM is 6MHz

#include "coefficients_46875_48000_60.h"

#define               L   128
#define               M   125
#define  IN_SAMPLE_RATE 46875
#define OUT_SAMPLE_RATE 48000


#elif defined(TEST_96000_44100)

// LCM is 14.112MHZ

#include "coefficients_96000_44100_60.h"

#define               L   147
#define               M   320
#define  IN_SAMPLE_RATE 96000
#define OUT_SAMPLE_RATE 44100

#endif


// Wav reading/writing code
#define    NUM_CHANNELS     2
#define      BLOCK_SIZE  1024

static int read_wav
(
    char *filename,
    int num_samples,
    int *left,
    int *right)
{
   int n = 0;
   float buffer[NUM_CHANNELS * BLOCK_SIZE];
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
         *left++ = (int) (32768.0f * (*bp++));
         *right++ = (int) (32768.0f * (*bp++));
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
    int *left,
    int *right)
{

   TinyWav tw;
   tinywav_open_write(&tw, NUM_CHANNELS, OUT_SAMPLE_RATE, TW_FLOAT32, TW_INTERLEAVED, filename);

   for (int i = 0; i < num_samples / BLOCK_SIZE; i++) {
      // NOTE: samples are always expected in float32 format,
      // regardless of file sample format

      float samples[BLOCK_SIZE * NUM_CHANNELS];

      for (int j = 0; j < BLOCK_SIZE; j++) {
         samples[2 * j]     = ((float) (*left++)) / 32768.0f;
         samples[2 * j + 1] = ((float) (*right++)) / 32768.0f;
      }

      tinywav_write_f(&tw, samples, BLOCK_SIZE);
   }

tinywav_close_write(&tw);
}

int main(int argc, char **argv) {
   int t = 0;
   if (argc < 3) {
      fprintf(stderr, "usage %s: infile outfile [ seconds ]\n", argv[0]);
   }
   char *infile = argv[1];
   char *outfile = argv[2];
   if (argc > 3) {
      t = atoi(argv[3]);
   }
   if (t <= 0) {
      t = 10;
   }

   int num_in_samples = t * IN_SAMPLE_RATE;
   int *ileft = malloc(num_in_samples * sizeof(int));
   int *iright = malloc(num_in_samples * sizeof(int));

   // Read in the WAV file at the input sample rate
   num_in_samples = read_wav(infile, num_in_samples, ileft, iright);

   int num_out_samples = num_in_samples * L / M;

   int *oleft = malloc(num_out_samples * sizeof(int));
   int *oright = malloc(num_out_samples * sizeof(int));

   int min_in = 0;
   int max_in = 0;
   int min_out = 0;
   int max_out = 0;

   for (int c = 0; c < 2; c++) {

      int m = 0;
      int *din = c ? iright : ileft;
      int *dout = c ? oright : oleft;

      while (m < num_out_samples) {

         // Calculate the sub filter to use for the mth sample
         int k = m * M % L;

         //Very messed up resampling
         //int k = rand() % L;

         // Calculate the most recent input sample
         int n = m * M / L;

         // Calculate the mth output sample
         int sum = 0;
         for (int p = 0; p < NTAPS / L; p++) {
            int d = (n - p) >= 0 ? din[n - p] : 0;
            if (d < min_in) {
               min_in = d;
            }
            if (d > max_in) {
               max_in = d;
            }
            sum += hc[p * L + k] * d;
         }
         sum >>= 15;
         if (sum < min_out) {
            min_out = sum;
         }
         if (sum > max_out) {
            max_out = sum;
         }
         dout[m++] = sum;
         //dout[m++] = din[n]; // very crude resampling
      }
   }

   printf("min_in  = %d\n", min_in);
   printf("max_in  = %d\n", max_in);
   printf("min_out = %d\n", min_out);
   printf("max_out = %d\n", max_out);

   // Write out the WAV file at the output sample rate
   write_wav(outfile, num_out_samples, oleft, oright);

   return 0;
}
