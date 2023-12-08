#!/bin/bash

# Script for managing assembly projects for x86 (using NASM and LD)

# Function to check and install dependencies
check_dependencies() {
    echo "Checking for required dependencies..."
    OS="$(uname -s)"
    case "$OS" in
        Linux*)
            sudo apt-get update && sudo apt-get install -y nasm gcc gdb
            # Install qemu if needed for emulation, not for compilation
            ;;
        Darwin*)
            brew install nasm gcc gdb
            ;;
        CYGWIN*|MINGW*)
            echo "Please install NASM, GCC, and GDB manually for Cygwin/MinGW."
            ;;
        *)
            echo "Unsupported OS. Please install NASM, GCC, and GDB manually."
            ;;
    esac
}

# Function to display usage instructions
usage() {
    echo "Usage: $0 [options] <source filename>"
    echo "Options:"
    echo "  -v, --verbose                Show detailed output."
    echo "  -g, --gdb                    Run gdb on the executable."
    echo "  -b, --break <breakpoint>     Add breakpoint in gdb."
    echo "  -r, --run                    Run program in gdb automatically."
    echo "  -q, --qemu                   Run executable in QEMU emulator (if qemu is installed)."
    echo "  -64, --x86-64                Compile for 64-bit x86 (default)."
    echo "  -32, --x86-32                Compile for 32-bit x86."
    echo "  -o, --output <filename>      Specify output filename."
    echo "  -l, --library <library>      Link external library (comma-separated for multiple)."
}

# Function to parse command-line arguments
parse_arguments() {
    BITS="64" # Default to 64-bit
    LIBRARIES=()
    VERBOSE=False
    GDB=False
    QEMU=False
    RUN=False
    while [[ $# -gt 0 ]]; do
        key="$1"
        case "$key" in
            -g|--gdb)
                GDB=True
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift # past argument
                ;;
            -v|--verbose)
                VERBOSE=True
                ;;
            -64|--x86-64)
                BITS="64"
                ;;
            -32|--x86-32)
                BITS="32"
                ;;
            -q|--qemu)
                QEMU=True
                ;;
            -r|--run)
                RUN=True
                ;;
            -b|--break)
                BREAK="$2"
                shift # past argument
                ;;
            -l|--library)
                IFS=',' read -r -a LIBRARIES <<< "$2"
                shift # past argument
                ;;
            *)
                # Assume it is the source file if it's not a known option
                if [[ -z $SOURCE_FILE ]]; then
                    SOURCE_FILE="$1"
                else
                    echo "Unknown option: $1"
                    usage
                    exit 1
                fi
                ;;
        esac
        shift # past argument or value
    done
    OUTPUT_FILE=${OUTPUT_FILE:-${SOURCE_FILE%.*}}
}

# Main function of the script
main() {
    check_dependencies

    parse_arguments "$@"

    if [[ -z $SOURCE_FILE ]]; then
        echo "Error: No source file specified."
        usage
        exit 1
    fi

    if [[ ! -f $SOURCE_FILE ]]; then
        echo "Error: Specified source file does not exist."
        exit 1
    fi

    if [[ $VERBOSE = True ]]; then
        echo "Configuration:"
        echo "Compiling for ${BITS}-bit."
        echo "Libraries: ${LIBRARIES[*]}"
    fi

    # Compilation and Linking process
    echo "Compiling for x86 architecture using NASM and LD."
    nasm_flags="-f elf${BITS}"
    ld_flags="-m elf_i386"
    [ "$BITS" = "64" ] && ld_flags="-m elf_x86_64"

    # Assemble the program
    nasm $nasm_flags "$SOURCE_FILE" -o "${OUTPUT_FILE}.o"
    if [ $? -ne 0 ]; then
        echo "Assembly failed"
        exit 1
    fi

    # Link the program
    ld $ld_flags "${OUTPUT_FILE}.o" -o "$OUTPUT_FILE" "${LIBRARIES[@]/#/-l}"
    if [ $? -ne 0 ]; then
        echo "Linking failed"
        exit 1
    fi

    if [[ $GDB = True ]]; then
        gdb_params=()
        if [[ $BREAK ]]; then
            gdb_params+=("-ex" "break ${BREAK}")
        fi
        if [[ $RUN = True ]]; then
            gdb_params+=("-ex" "run")
        fi
        echo "Running GDB debugger."
        gdb "${gdb_params[@]}" "$OUTPUT_FILE"
    fi

    if [[ $QEMU = True ]]; then
        echo "Running executable in QEMU."
        qemu-system-i386 -drive format=raw,file="$OUTPUT_FILE"
    fi
}

# Invoke main function with all passed arguments
main "$@"
