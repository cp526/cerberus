// Options:   --no-pointers --no-structs --no-unions --argc --no-bitfields --checksum --comma-operators --compound-assignment --concise --consts --divs --embedded-assigns --pre-incr-operator --pre-decr-operator --post-incr-operator --post-decr-operator --unary-plus-operator --jumps --longlong --int8 --uint8 --no-float --main --math64 --muls --safe-math --no-packed-struct --no-paranoid --no-volatiles --no-volatile-pointers --const-pointers --no-builtins --max-array-dim 1 --max-array-len-per-dim 4 --max-block-depth 1 --max-block-size 10 --max-expr-complexity 4 --max-funcs 10 --max-pointer-depth 2 --max-struct-fields 2 --max-union-fields 2 -o csmith_380.c
#include "csmith.h"


static long __undefined;



static int32_t g_3 = 0x860B4FFBL;



static uint8_t  func_1(void);




static uint8_t  func_1(void)
{ 
    uint16_t l_2[3];
    int i;
    for (i = 0; i < 3; i++)
        l_2[i] = 65535UL;
    for (g_3 = 0; (g_3 <= 2); g_3 += 1)
    { 
        return l_2[2];
    }
    g_3 = (safe_lshift_func_int8_t_s_s(l_2[1], 5));
    return g_3;
}





int main (int argc, char* argv[])
{
    int print_hash_value = 0;
    if (argc == 2 && strcmp(argv[1], "1") == 0) print_hash_value = 1;
    platform_main_begin();
    crc32_gentab();
    func_1();
    transparent_crc(g_3, "g_3", print_hash_value);
    platform_main_end(crc32_context ^ 0xFFFFFFFFUL, print_hash_value);
    return 0;
}
