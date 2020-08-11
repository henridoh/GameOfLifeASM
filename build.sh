#!/bin/bash
if ! type nasm &>> /dev/null
    then
    echo "NASM not found. Installing it..."
    sudo apt install nasm -y
fi
if ! type ld &>> /dev/null
    then
    echo "Binutils not found. Installing it..."
    sudo apt install binutils -y
fi
if nasm -felf64 GameOfLife.asm
    then
    if ld -m elf_x86_64 GameOfLife.o -o GameOfLife
        then strip GameOfLife --strip-all
        rm GameOfLife.o
    fi
fi
