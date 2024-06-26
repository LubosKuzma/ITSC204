#! /bin/bash

# Evan Stoakes
# ITSC204

# there is a bit missing. If you reinstall gdb and gef multiple times with this script it will add a billion lines
# to ~/.gdbinit and read the same lines. No effect on GEF, just makes load up take longer. Adding a check
# to avoid adding the line if it's already present would be great

# Since this script installs pre-reqs and the toolchain, the prompts could be changed to flags if you feel like it 

#Set stricker error handling (optional)
set -euo pipefail

#Color definition
ERROR_COLOR="\e[31m"
RESET_COLOR="\e[em"
WARN_COLOR ="\e[33m"
INFO_COLOR="\e[32m"

#Script information.
SCRIPT_NAME=$(basename "$0")
#Version
VERSION="1.0.1"

#Function for informatio error message
error_exit(){
    local msg-"<span class="math-inline">1"
    echo \-e "</span>{ERROR_COLOR}Error:${RESET_COLOR} $msg"
}

#Function to print script usage (Propose change from the original)
print_usage(){
    echo "Usage:"
    echo ""
    echo "  $SCRIPT_NAME [ options ] <assembly filename> [-o | --output <output filename>]"
    echo ""
    echo "  -v | --verbose                Show detailed information about steps performed."
    echo "  -g | --gdb                    Run gdb command on the executable."
    echo "  -b | --break <break point>    Add breakpoint after running gdb. Default is _start."
    echo "  -r | --run                    Run program in gdb automatically (same as 'run' command inside gdb)."
    echo "  -q | --qemu                   Run executable in QEMU emulator."
    echo "  -64| --x86-64                 Compile for 64bit (x86-64) system."
    echo "  -o | --output <filename>      Output filename."
    echo "  -h | --help                   Display this help message."
    echo ""
    exit 1
}

# Parse command-line arguments with getopts
GDB=false
OUTPUT_FILE=""
VERBOSE=false
BITS=false
QEMU=false
BREAK="_start"
RUN=false
CLEANUP=false
while getopts ":vg:b:ro:q64h:c" opt; do
  case $opt in
    v) VERBOSE=true ;;
    g) GDB=true ;;
    b) BREAK="$OPTARG" ;;  # Validate breakpoint format later
    r) RUN=true ;;
    o) OUTPUT_FILE="<span class="math-inline">OPTARG" ;;
q\) QEMU\=true ;;
64\) BITS\=true ;;
h\) print\_usage ;;
c\) CLEANUP\=true ;;  \# Add cleanup option \(optional\)
\\?\) echo \-e "</span>{WARN_COLOR}Warning:${RESET_COLOR} Unknown option -<span class="math-inline">OPTARG" \>&2; exit 1 ;;
\:\)  echo \-e "</span>{WARN_COLOR}Warning:${RESET_COLOR} Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Shift remaining arguments to positional parameters
shift $((OPTIND-1))  # Adjust for getopts parsing

#Validate input filename existence
if [[ ! -f "$1" ]]; then
  error_exit "Specified file '$1' does not exist."
fi

# Set default output filename if not provided
if [[ -z "<span class="math-inline">OUTPUT\_FILE" \]\]; then
OUTPUT\_FILE\="</span>{1%.*}"
fi

# Verbose output with timestamp
if [[ "<span class="math-inline">VERBOSE" \=\= true \]\]; then
echo \-e "</span>{INFO_COLOR}[<span class="math-inline">\(date \+'%Y\-%m\-%d %H\:%M\:%S'\)\] Arguments being set\:</span>{RESET_COLOR}"
  echo "  GDB = ${GDB}"
  echo "  RUN = ${RUN}"
  echo "  BREAK = ${BREAK}"
  echo "  QEMU = ${QEMU}"
  echo "  CLEANUP = ${CLEANUP}"  # Optional cleanup flag
  echo "  Input File = $1"
  echo "  Output File = <span class="math-inline">OUTPUT\_FILE"
echo ""
echo \-e "</span>{INFO_COLOR}[<span class="math-inline">\(date \+'%Y\-%m\-%d %H\:%M\:%S'\)\] NASM started\.\.\.</span>{RESET_COLOR}"
fi

# Compile assembly based on architecture
if [[ "$BITS" == true ]]; then
  nasm -f elf64 "$1" -o "$OUTPUT_FILE.o" && echo ""
else
  nasm -f elf "$1" -o "$OUTPUT_FILE.o" && echo ""
fi

# Suppress unnecessary echo in non-verbose mode
if [[ "$VERBOSE" != true ]]; then
  nasm -f elf "$1" -o "$OUTPUT_FILE.o" > /dev/

# Linking and optional cleanup (consider adding error handling for linking)
ld -o "$OUTPUT_FILE" "$OUTPUT_FILE.o"  # Link object file to executable

if [[ "$CLEANUP" == true ]]; then
  rm -f "$OUTPUT_FILE.o"  # Optional cleanup (remove object file)
fi

# Conditional output based on verbose mode
if [[ "$VERBOSE" == true ]]; then
  echo -e "${INFO_COLOR}[$(date +'%Y-%m-%d %H:%M:%S')] Linking finished.${RESET_COLOR}"
fi

# Script execution based on options
if [[ "$GDB" == true ]]; then
  gdb "$OUTPUT_FILE" -ex "break $BREAK"  # Set breakpoint before starting gdb
  if [[ "$RUN" == true ]]; then
    gdb -command="run"  # Run the program in gdb after setting breakpoint
  fi
elif [[ "$QEMU" == true ]]; then
  #  Add logic to run the executable in QEMU emulator (consider user-provided options)
  echo -e "${WARN_COLOR}Warning:${RESET_COLOR} QEMU emulation not currently implemented."
fi


# Original Script below: 
# Compile assembly based on architecture
if [[ "<span class="math-inline">BITS" \=\= true \]\]; then
nasm \-f elf64 "</span>{1}" -o "<span class="math-inline">OUTPUT\_FILE\.o" && echo ""
else
nasm \-f elf "</span>{1}" -o "$OUTPUT_FILE.o" && echo ""
fi

# Verbose linking output
if


if [ "$(id -u)" == 0 ]; then                                                                                    # checks for root
    echo -e "\e[1:31mPlease do not run in root\e[0m"
    exit 1
fi

echo -e "You may be prompted for a password. Do not be alarmed, this is normal\nx86, arm, or q?"

while true; do
    
    read archval

    if [[ "$archval" == "x86" ]] || [[ "$archval" == "X86" ]]; then                                             # installs x86_toolchain.sh and qemu
        if ! [ -x "$(command -v x86_toolchain.sh)" ]; then                                                      # checks if the toolchain exists
            sudo wget -P /usr/bin/ https://raw.githubusercontent.com/LubosKuzma/ITSC204/main/scripts/x86_toolchain.sh
            sudo chmod +x /usr/bin/x86_toolchain.sh
            break
        
        else
            echo -e "\e[1;36mx86_toolchain.sh is already installed\e[0m"
            break
        fi

    elif [[ "$archval" == "arm" ]] || [[ "$archval" == "ARM" ]]; then                                           # installs arm_toolchain.sh
        if ! [ -x "$(command -v arm_toolchain.sh)" ]; then                                                      # checks if the toolchain doesn't exist
            sudo apt-get install gcc-arm-linux-gnueabihf -y
            sudo t-get install gdb-multiarch -y
            wget -P /usr/bin https://raw.githubusercontent.com/LubosKuzma/ITSC204/main/scripts/arm_toolchain.sh
            sudo chmod +x /usr/bin/arm_toolchain.sh
            break

        else
            echo "\e[1;36marm_toolchain.sh is already installed\e[0m"
            break
        fi

    elif [[ "$archval" == "Q" ]] || [[ "$archval" == "q" ]]; then                                               # I don't know what this does
        exit 0

    else
        echo -e "\e[1;31mPlease enter either 'arm' or 'x86'\e[0m"

    fi
done

if ! [ -x "$(command -v gdb)" ]; then                                                                           # checks for and installs gdb and gef
    echo -e "\e[0;31gdb not found. Installing....\e[0m\nThis may take a few minutes"
    sudo apt-get update
    sudo apt-get install gdb -y
    wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/py
    echo source ~/.gdbinit-gef.py >> ~/.gdbinit


elif ! [ -f ~/.gdbinit-gef.py ]; then                                                                           # makes sure gef is installed
    echo -e "\e[0;31mgef missing. Installing files\e[0m"
    wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/py
    echo source ~/.gdbinit-gef.py >> ~/.gdbinit
else
    echo -e "\e[0;36mgdb ready\e[0m"
fi

if ! dpkg -l qemu-user > /dev/null 2>&1; then                                                                   # checks and installs qemu-user if missing
    echo "Installing qemu-user"         
    sudo apt-get install qemu-user -y 2>&1

else
    echo -e "\e[1;36mqemu ready\e[0m"
fi

exit 0
