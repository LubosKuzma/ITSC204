#Created by Natnael Araya
# ISS Program, SADT, SAIT
# 2nd Version-December 2023

#!/bin/bash

# Toolchain Script for Managing Assembly Projects for x86 and ARM (Raspberry Pi 3B/4)
# This script supports 64-bit systems by default and includes options for 32-bit and ARM architectures.

# Function to check and install dependencies
check_dependencies() {
    echo "Checking for required dependencies..."
    OS="$(uname -s)"
    case "$OS" in
        Linux*)
            # Dependencies for both x86 and ARM
            sudo apt-get update && sudo apt-get install -y nasm gcc gdb qemu-user-static
            ;;
        Darwin*)
            # macOS dependencies (primarily x86)
            brew install nasm gcc gdb
            ;;
        CYGWIN*|MINGW*)
            # Manual installation prompt for Windows-based systems
            echo "Please install NASM, GCC, and GDB manually for Cygwin/MinGW."
            ;;
        *)
            # Fallback for unsupported OS
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
    echo "  -q, --qemu                   Run executable in QEMU emulator (if installed)."
    echo "  -64, --x86-64                Compile for 64-bit x86 (default)."
    echo "  -32, --x86-32                Compile for 32-bit x86."
    echo "  -arm, --arm                  Compile for ARM architecture (Raspberry Pi 3B/4)."
    echo "  -o, --output <filename>      Specify output filename."
    echo "  -l, --library <library>      Link external library (comma-separated for multiple)."
}

# Function to parse command-line arguments
parse_arguments() {
    ARCH="x86-64" # Default to 64-bit x86
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
                ARCH="x86-64"
                ;;
            -32|--x86-32)
                ARCH="x86-32"
                ;;
            -arm|--arm)
                ARCH="arm"
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
                # Assume it is the source file if not a known option
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
        echo "Compiling for ${ARCH}."
        echo "Libraries: ${LIBRARIES[*]}"
    fi

    # Compilation and Linking process
    echo "Compiling for ${ARCH} using NASM and LD."
    case "$ARCH" in
        "x86-64")
            nasm_flags="-f elf64"
            ld_flags="-m elf_x86_64"
            ;;
        "x86-32")
            nasm_flags="-f elf32"
            ld_flags="-m elf_i386"
            ;;
        "arm")
            # ARM-specific flags (for Raspberry Pi)
            nasm_flags="-f elf32"
            ld_flags="-m armelf"
            ;;
    esac

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

    # GDB and QEMU handling
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
        qemu-system-${ARCH} -drive format=raw,file="$OUTPUT_FILE"
    fi
}

# Invoke main function with all passed arguments
main "$@"
