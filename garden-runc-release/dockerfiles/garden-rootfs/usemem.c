#include <stdlib.h>
#include <stdio.h>

int main()
{
  int n = 0;

  while (1) {
    if (malloc(1<<20) == NULL) {
      printf("malloc failure after %d MiB\n", n);
      return 0;
    }
    printf("got %d MiB\n", ++n);
  }
}
