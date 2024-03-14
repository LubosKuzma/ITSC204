#! /bin/bash

# Created by Evan Stoakes
# Modified by Max Daigle
# SAIT - ITSC204
# March 2024


#COLOUR CODES
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NONE='\033[0m'

#SYSTEM IDENTIFICATION

distro=`cat /etc/os-release`
kernel=`uname -m`
if [[ $distro =~ "arch" ]] ; then
    echo -e "Detected package manager: ${PURPLE}Pacman${NONE}\n"
    install="pacman -S"
    update="pacman -Syu"
    search="pacman -Q"
elif [[ $distro =~ "debian" || $distro =~ "ubuntu" ]]; then
    echo -e "Detected package manager: ${PURPLE})Aptitude${NONE}\n"
    install="apt install"
    update="apt-get update"
    search="dpkg -l"
elif [[ $distro =~ "fedora" ]]; then
    echo -e "Detected package manager: ${PURPLE}DNF/RPM${NONE}\n"
    install="dnf install"
    update="dnf upgrade"
    search="dnf list installed"
elif [[ $distro =~ "openSUSE" ]]; then
    echo -e "Detected package manager: ${PURPLE}Zypper${NONE}\n"
    install="zypper install"
    update="zypper ref && zypper update"
    search="zypper se -i"
elif [[ $distro =~ "alpine" ]]; then
    echo -e "Detected package manager: ${PURPLE}APK${NONE}\n"
    install="apk add"
    update="apk update"
    search="apk list -i"
else
    echo -e "Package manager not detected, attempt install with Aptitude?(y/n)"
    read answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    	install="apt-get install"
    	update="apt-get update"
    	search="dpkg -l"
    else
    	exit 1
    fi
fi

 




#MAIN

if [ "$(id -u)" == 0 ]; then                                                                                    # checks for root
    echo -e "${RED}Please do not run in root${NONE}"
    exit 1
fi

echo -e "You may be prompted for a password. Do not be alarmed, this is normal.\n${CYAN}x86${NONE}, ${RED}arm${NONE}, or (q)uit?"

while true; do
    
    read archval

    if [[ "$archval" == "arm" ]] && [[ "$kernel" =~ x86_64 ]]; then
        echo -e "${RED}Uname reports this as being an x86 system, please try again.${NONE}\n"
        exit 0
    elif [[ "$archval" == "x86" ]] || [[ "$archval" == "X86" ]] && [[ "$kernel" =~ "aarch64" ]] || [[ "$kernel" =~ "arm" ]]; then
        echo -e "${RED}Uname reports this as being an ARM system, please try again.${NONE}"
        exit 0
        

    elif [[ "$archval" == "x86" ]] || [[ "$archval" == "X86" ]]; then                                             # installs x86_toolchain.sh and qemu
        if ! [ -x "$(command -v x86_toolchain.sh)" ]; then                                                      # checks if the toolchain exists
            sudo wget -P /usr/bin/ https://raw.githubusercontent.com/LubosKuzma/ITSC204/main/scripts/x86_toolchain.sh
            sudo chmod +x /usr/bin/x86_toolchain.sh
            break
        
        else
            echo -e "${GREEN}x86_toolchain.sh is already installed${NONE}"
            break
        fi

    elif [[ "$archval" == "arm" ]] || [[ "$archval" == "ARM" ]]; then                                           # installs arm_toolchain.sh
        if ! [ -x "$(command -v arm_toolchain.sh)" ]; then                                                      # checks if the toolchain doesn't exist
            sudo $install gcc-arm-linux-gnueabihf -y
            sudo $install gdb-multiarch -y
            wget -P /usr/bin https://raw.githubusercontent.com/LubosKuzma/ITSC204/main/scripts/arm_toolchain.sh
            sudo chmod +x /usr/bin/arm_toolchain.sh
            break

        else
            echo "${GREEN}arm_toolchain.sh is already installed${NONE}\n"
            break
        fi

    elif [[ "$archval" == "Q" ]] || [[ "$archval" == "q" ]]; then                                          #Exits if 'Q' or 'q' selected
        exit 0

    else
        echo -e "${RED}Please enter either 'arm' or 'x86'${NONE}\n"

    fi
done

if ! [ -x "$(command -v gdb)" ]; then                                    #checks for and installs gdb and gef
    echo -e "${RED}gdb not found. Installing....\nThis may take a few minutes${NONE}"
    sudo $update
    sudo $install gdb -y
    wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/py
    echo source ~/.gdbinit-gef.py >> ~/.gdbinit


elif ! [ -f ~/.gdbinit-gef.py ]; then                        #makes sure gef is installed and checks .gdbinit confirms with .gdbinit
    echo -e "${RED}gef missing. Installing files${NONE}"
    wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/py
    if ! grep -q "source ~/.gdbinit-gef.py" ~/.gdbinit; then    #checks that gef is not already present in .gdbinit
        echo source ~/.gdbinit-gef.py >> ~/.gdbinit
    fi
else
    
    echo -e "${GREEN}gdb ready${NONE}"
    echo -e "${GREEN}gef ready${NONE}"
fi

if ! $search qemu-user > /dev/null 2>&1; then        #checks and installs qemu-user if missing
    echo "Installing qemu-user"         
    sudo $install qemu-user

else
    echo -e "${GREEN}qemu ready${NONE}"
fi

echo -e "To disable GEF, comment out the line ${CYAN}'source ~/.gdbinit-gef.py' ${NONE}in ${CYAN}~/.gdbinit${NONE}" 
exit 0
