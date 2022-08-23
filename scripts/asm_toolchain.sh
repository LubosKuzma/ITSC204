# Created by Lubos Kuzma
# ISS Program, SADT, SAIT
# August 2022

#! /bin/bash

if [ $# -lt 1 ]; then
        echo "Usage:"
        echo "asm_toolchain.sh [-v | --verbose] [-g | --gdb] [-q | --qemu] [-64] <assembly filename> [-o | --output <output filename>]"
        exit 1
fi

POSITIONAL_ARGS=()
GDB=False
OUTPUT_FILE=""
VERBOSE=False
BITS=False
QEMU=False
while [[ $# -gt 0 ]]; do
        case $1 in
                -g|--gdb)
                        GDB=True
                        shift # past argument
                        ;;                                                                                                                                                                                                                 
                -o|--output)                                                                                                                                                                                                               
                        OUTPUT_FILE="$2"                                                                                                                                                                                                   
                        shift # past argument                                                                                                                                                                                              
                        shift # past value                                                                                                                                                                                                 
                        ;;                                                                                                                                                                                                                 
                -v|--verbose)                                                                                                                                                                                                              
                        VERBOSE=True                                                                                                                                                                                                       
                        shift # past argument                                                                                                                                                                                              
                        ;;                                                                                                                                                                                                                 
                -64)                                                                                                                                                                                                                       
                        BITS=True                                                                                                                                                                                                          
                        shift # past argument                                                                                                                                                                                              
                        ;;                                                                                                                                                                                                                 
                -q|--qemu)                                                                                                                                                                                                                 
                        QEMU=True
                        shift # past argument
                        ;;
                -*|--*)
                        echo "Unknown option $1"
                        exit 1
                        ;;
                *)
                        POSITIONAL_ARGS+=("$1") # save positional arg
                        shift # past argument
                        ;;
        esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ ! -f $1 ]]; then
        echo "Specified file does not exist"
        exit 1
fi

if [ "$OUTPUT_FILE" == "" ]; then
        OUTPUT_FILE=${1%.*}
fi

if [ "$VERBOSE" == "True" ]; then
        echo "Arguments being set:"
        echo "  GDB = ${GDB}"
        echo "  QEMU = ${QEMU}"
        echo "  Input File = $1"
        echo "  Output File = $OUTPUT_FILE"
        echo "  Verbose = $VERBOSE"
        echo "  64 bit mode = $BITS" 
        echo ""

        echo "NASM started..."

fi

if [ "$BITS" == "True" ]; then

        nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""


elif [ "$BITS" == "False" ]; then

        nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""

fi

if [ "$VERBOSE" == "True" ]; then

        echo "NASM finished"
        echo "Linking ..."

fi

if [ "$VERBOSE" == "True" ]; then

        echo "NASM finished"
        echo "Linking ..."
fi

if [ "$BITS" == "True" ]; then

        ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""


elif [ "$BITS" == "False" ]; then

        ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi


if [ "$VERBOSE" == "True" ]; then

        echo "Linking finished"

fi

if [ "$QEMU" == "True" ]; then

        echo "Starting QEMU ..."
        echo ""

        if [ "$BITS" == "True" ]; then

                qemu-x86_64 $OUTPUT_FILE && echo ""

        elif [ "$BITS" == "False" ]; then

                qemu-i386 $OUTPUT_FILE && echo ""

        fi

        exit 0

fi

if [ "$GDB" == "True" ]; then

        gdb $OUTPUT_FILE
fi
