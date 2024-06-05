##
## EPITECH PROJECT, 2023
## MinilibC
## File description:
## Makefile
##

NAME = libmy_malloc.so

SRC = my_malloc.asm \

OBJ = $(SRC:.asm=.o)

all: $(NAME)

$(NAME): $(OBJ)
	gcc -shared -o $@ $^ -z execstack

%.o: %.asm
	nasm -f elf64 $< -o $@

clean:
	rm -rf $(OBJ)

fclean: clean
	rm -rf $(NAME)

re: fclean all
