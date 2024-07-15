#include "refinedc.h"

//CN_VIP #include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>
int y=2, x=1;
int main() {
  uintptr_t ux = (uintptr_t)&x;
  uintptr_t uy = (uintptr_t)&y;
  uintptr_t offset = 4;
  ux = ux + offset;
#if defined(ANNOT)
  int *p = copy_alloc_id(ux, &y);
#else
  int *p = (int *)ux; // does this have undefined behaviour?
#endif
  int *q = &y;
  //CN_VIP printf("Addresses: &x=%p p=%p &y=%"PRIxPTR\
         "\n",(void*)&x,(void*)p,(unsigned long)uy);
  if (memcmp(&p, &q, sizeof(p)) == 0) {
    *p = 11; // does this have undefined behaviour?
    //CN_VIP printf("x=%d  y=%d  *p=%d  *q=%d\n",x,y,*p,*q);
  }
}
