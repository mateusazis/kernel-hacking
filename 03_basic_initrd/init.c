#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  printf("Hello world! Sleeping forever...\n");
  while (1) {
    sleep(99999);
  }
  return 0;
}
