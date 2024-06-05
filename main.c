/*
** EPITECH PROJECT, 2023
** MinilibC
** File description:
** main.c
*/

#include "my_malloc.h"
#include <stddef.h>

int main(void)
{   
    char **str = mmalloc(sizeof(char *) * 6);
    char *test = NULL;

    str[0] = mmalloc(sizeof(char) * 17);
    str[1] = mmalloc(sizeof(char) * 10);
    str[2] = mmalloc(sizeof(char) * 13);
    str[3] = mmalloc(sizeof(char) * 22);
    str[4] = mmalloc(sizeof(char) * 27);

    show_malloc();
    mmalloc(sizeof(char) * 5000);
    // printf("%lld\n", malloc(sizeof(char) * 5000));
    // printf("%lld\n", (void *)((long)str - 8192));
    // str[5] = (void *)((long)str - 8192);
    // show_malloc();
    return 0;

}
