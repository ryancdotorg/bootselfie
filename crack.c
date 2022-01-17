#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <fcntl.h>
#include <unistd.h>

#define BILLION 1000000000ULL;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
static uint64_t getns() {
  uint64_t ns;
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  ns  = ts.tv_nsec;
  ns += ts.tv_sec * BILLION;
  return ns;
}

static double nstofs(uint64_t ns) {
  double s = ((double)ns) / 1e9;
  return s;
}

static uint64_t fstons(double s) {
  double ns = s * 1e9;
  return (uint64_t)ns;
}
#pragma GCC diagnostic pop

static const unsigned char allowed[] = {
   2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 16, 17, 18, 19, 20, 21, 22,
  23, 24, 25, 26, 27, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 43, 44,
  45, 46, 47, 48, 49, 50, 51, 52, 53, 57
};

int main() {
  uint64_t ts, dt, counter = 0;
  unsigned char seed[] = { 0,  0,  0,  0,  0,  0};
  uint8_t key[256], S[256], Z[256], ct[768];
  unsigned short i, j, k, t, p;

  // one time setup
  for (i = 0; i < 256; ++i) Z[i] = i;
  int fd = open("image.pal", O_RDONLY);
  read(fd, ct, 768);
  close(fd);

  ts = getns();
  for (;;) {
    // each key
    memcpy(S, Z, 256);
    for (j = 0; j < sizeof(seed); ++j) key[j] = allowed[seed[j]];
    for (i = 0; j < 256; ++i, ++j) key[j] = key[i];
    for (i = 0, j = 0; i < 256; ++i) {
      j = (j + key[i] + S[i]) & 0xff;
      t = S[i]; S[i] = S[j]; S[j] = t;
    }

    i = j = 0;
    for (p = 0; p < sizeof(ct); ++p) {
      i = (i + 1) & 0xff;
      j = (j + S[i]) & 0xff;
      t = S[i]; S[i] = S[j]; S[j] = t;
      k = S[(S[i] + S[j]) & 0xff];
      /*
      if (p > 10) {
        key[sizeof(seed)] = 0;
        printf("%s %9zu ct[%3u]:%02x~%02x\n", key, counter, p, ct[p], k);
      }
      */
      k = (k ^ ct[p]) & 0xc0;
      if (k) break;
    }

    if (p > 700) {
      printf("Solved! ");
      for (unsigned int i = 0; i < sizeof(seed); ++i) {
        printf("%02x", key[i]);
      }
      printf("\n");
      break;
    } else if (p > 7) {
      printf("Close? %3u %9zu ", p, counter);
      for (unsigned int i = 0; i < sizeof(seed); ++i) {
        printf("%02x", key[i]);
      }
      printf("\n");
    }

    for (int digit = 5; digit >= 0; --digit) {
      if (++seed[digit] > sizeof(allowed)) {
        seed[digit] = 0;
      } else {
        break;
      }
    }

    ++counter;
  }
  dt = getns() - ts;
  printf("checked %9zu in: %10.6f sec\n", counter, nstofs(dt));

  return 0;
}
