#! /bin/bash

# Evan Stoakes
# ITSC204

# there is a bit missing. If you reinstall gdb and gef multiple times with this script it will add a billion lines
# to ~/.gdbinit and read the same lines. No effect on GEF, just makes load up take longer. Adding a check
# to avoid adding the line if it's already present would be great

# Since this script installs pre-reqs and the toolchain, the prompts could be changed to flags if you feel like it 

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
