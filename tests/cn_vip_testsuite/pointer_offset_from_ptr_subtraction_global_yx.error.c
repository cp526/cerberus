//CN_VIP #include <stdio.h>
#include <string.h>
#include <stddef.h>
int y=2, x=1;
int main() {
  int *p = &x;
  int *q = &y;
  ptrdiff_t offset = q - p;
  int *r = p + offset;
  if (memcmp(&r, &q, sizeof(r)) == 0) {
    *r = 11; // is this free of UB?
    //CN_VIP printf("y=%d *q=%d *r=%d\n",y,*q,*r);
  }
}
