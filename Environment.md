# Preparing environment for **Intel X86 assembly** in Kali
- Install NASM - **sudo apt-get install nasm**
- Install VSCode - **sudo apt-get install code**
- Install assembly extension inside VS Code - extension name: nasm
- Assign the above extension to **.s** files
- Install GDB - **sudo apt-get install gdb**
- Install GEF - https://github.com/hugsy/gef
- Create / download x-86_toolchain.sh script
- Make the above script executable
- Add the above script to PATH:
  **echo 'export PATH=$PATH:~/ITSC204/scripts' >> .bashrc
  Note: writing it to .bashrc makes the path persistent within bash
