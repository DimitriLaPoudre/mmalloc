##
## EPITECH PROJECT, 2023
## MinilibC
## File description:
## Makefile
##

NAME = test

SRC = main.c \

OBJ = $(SRC:.c=.o)

CFLAGS = -I./include -L./src -lmy_malloc

all: $(NAME)

$(NAME): $(OBJ)
	make -C src
	gcc $(OBJ) -o $(NAME) $(CFLAGS)

.PHONY: run

run:
	@$(MAKE) -s re
	@echo "#! /bin/bash" >> run
	@echo export LD_LIBRARY_PATH='"./src:$$''LD_LIBRARY_PATH"' >> run
	@echo export LD_PRELOAD='"./src/libmy_malloc.so:$$''LD_PRELOAD"' >> run
	@echo ./$(NAME)>> run
	@chmod 777 run
	@-./run
	@rm -rf run
	@$(MAKE) -s fclean

clean:
	make -C src clean
	rm -rf $(OBJ)

fclean: clean
	make -C src fclean
	rm -rf $(NAME)

re: fclean all
