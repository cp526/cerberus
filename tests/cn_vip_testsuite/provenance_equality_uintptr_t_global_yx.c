//CN_VIP #include <stdio.h>
#include <inttypes.h>
int y=2, x=1;
int main() {
  uintptr_t p = (uintptr_t)(&x + 1);
  uintptr_t q = (uintptr_t)&y;
  //CN_VIP printf("Addresses: p=%" PRIxPTR " q=%" PRIxPTR "\n",
         (unsigned long)p,(unsigned long)q);
  _Bool b = (p==q);
  // can this be false even with identical addresses?
  //CN_VIP printf("(p==q) = %s\n", b?"true":"false");
  return 0;
}
