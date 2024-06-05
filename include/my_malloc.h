/*
** EPITECH PROJECT, 2023
** Library
** File description:
** header.h
*/

#ifndef MINILIBC_
    #define MINILIBC_

void *mmalloc(unsigned long);

void mfree(void *);

void *mcalloc(unsigned long, unsigned long);

void *mrealloc(void *, unsigned long);

void show_malloc(void);

#endif
