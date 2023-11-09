#! /bin/bash

# Created by Lubos Kuzma
# modified 
# ISS Program, SADT, SAIT
# August 2022


if [ $# -lt 1 ]; then
    echo "Usage:"
    echo ""
    echo "gcc_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
    echo ""
    echo "-v | --verbose                Show some information about steps performed."
    echo "-g | --gdb                    Run gdb command on executable."
    echo "-b | --break <break point>    Add breakpoint after running gdb. Default is main."
    echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
    echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
    echo "-m32| --32                    Compile for 32bit (x86) system."
    echo "-m64| --64                    Compile for 64bit (x86-64) system."
    echo "-o | --output <filename>      Output filename."
    exit 1
fi

POSITIONAL_ARGS=()
GDB=False
OUTPUT_FILE=""
VERBOSE=False
BITS=""
QEMU=False
BREAK="main"
RUN=False
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
        -m32|--32)
            BITS="-m32"
            shift # past argument
            ;;
        -m64|--64)
            BITS="-m64"
            shift # past argument
            ;;
        -q|--qemu)
            QEMU=True
            shift # past argument
            ;;
        -r|--run)
            RUN=True
            shift # past argument
            ;;
        -b|--break)
            BREAK="$2"
            shift # past argument
            shift # past value
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
    echo "  RUN = ${RUN}"
    echo "  BREAK = ${BREAK}"
    echo "  QEMU = ${QEMU}"
    echo "  Input File = $1"
    echo "  Output File = $OUTPUT_FILE"
    echo "  Verbose = $VERBOSE"
    echo "  Bits = $BITS" 
    echo ""
fi

GCC_FLAGS=""
if [ "$BITS" != "" ]; then
    GCC_FLAGS="$BITS"
fi

echo "GCC compilation started..."

gcc $GCC_FLAGS -x assembler -o $OUTPUT_FILE $1

if [ $? -ne 0 ]; then
    echo "Compilation failed"
    exit 1
fi

if [ "$VERBOSE" == "True" ]; then
    echo "GCC compilation finished"
fi

if [ "$GDB" == "True" ]; then
    if [ "$RUN" == "True" ]; then
        gdb -ex "break ${BREAK}" -ex run -ex quit --args ./$OUTPUT_FILE
    else
        gdb -ex "break ${BREAK}" --args ./$OUTPUT_FILE
    fi
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

	gdb_params=()
	gdb_params+=(-ex "b ${BREAK}")

	if [ "$RUN" == "True" ]; then

		gdb_params+=(-ex "r")

	fi

	gdb "${gdb_params[@]}" $OUTPUT_FILE

fi
