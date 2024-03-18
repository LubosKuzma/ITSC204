#! /bin/bash							# bash script - should be executed in bash

# Created by Lubos Kuzma
# ISS Program, SADT, SAIT
# August 2022

# Checking to see if the number of command-line arguments is less than 1, then displays the following message and exits
if [ $# -lt 1 ]; then						
	echo "Usage:"						
	echo ""
	echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
	echo ""
	echo "-v | --verbose                Show some information about steps performed."
	echo "-g | --gdb                    Run gdb command on executable."
	echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
	echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
	echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
	echo "-64| --x86-64                 Compile for 64bit (x86-64) system."
	echo "-o | --output <filename>      Output filename."

	exit 1
fi

POSITIONAL_ARGS=()
GDB=False
OUTPUT_FILE=""
VERBOSE=False
BITS=True							#changes the default setting to 64 bits
QEMU=False
BREAK="_start"
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
		-64|--x84-64)
			BITS=True
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

# updates positional arguments stored in the POSITIONAL_ARGS array
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# checks if the first positional argument is incorrect - then prints an error message.
if [[ ! -f $1 ]]; then
	echo "Specified file does not exist"
	exit 1
fi

#checks if the OUTPUT_FILE variable is empty
if [ "$OUTPUT_FILE" == "" ]; then
	OUTPUT_FILE=${1%.*}
fi

#checks if the verbose value is "True", then prints the following arguments
if [ "$VERBOSE" == "True" ]; then
	echo "Arguments being set:"
	echo "	GDB = ${GDB}"
	echo "	RUN = ${RUN}"
	echo "	BREAK = ${BREAK}"
	echo "	QEMU = ${QEMU}"
	echo "	Input File = $1"
	echo "	Output File = $OUTPUT_FILE"
	echo "	Verbose = $VERBOSE"
	echo "	64 bit mode = $BITS" 
	echo ""

	echo "NASM started..."

fi

# checks if BITS are valued at "True" or "False" and changes the format to 64-bit and 32-bit, respectively and starts NASM
if [ "$BITS" == "True" ]; then

	nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""


elif [ "$BITS" == "False" ]; then

	nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""

fi

# checks if verbose is set to "True", prints the following
if [ "$VERBOSE" == "True" ]; then

	echo "NASM finished"
	echo "Linking ..."
	
fi

# checks if BITS are valued at "True" or "False" and uses the ld linker to link the object file into an executable for its respective architecture
if [ "$BITS" == "True" ]; then

	ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""


elif [ "$BITS" == "False" ]; then

	ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi

# prints if verbose is "True"
if [ "$VERBOSE" == "True" ]; then

	echo "Linking finished"

fi

# checks if the emulator QEMU value is "True"; if so, start the QEMU based on the bit architecture
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

# checks if the GDB value is "True"; if so, creates an array "gdb_params"
if [ "$GDB" == "True" ]; then

	gdb_params=()

  	# adds a BREAK parameter
	gdb_params+=(-ex "b ${BREAK}")

	# if the RUN value is "True", adds a run command
	if [ "$RUN" == "True" ]; then

		gdb_params+=(-ex "r")

	fi

	# executes the GDB debugger with saved parameters and the executable file
	gdb "${gdb_params[@]}" $OUTPUT_FILE

fi
