import argparse
import subprocess
import logging

def run_command(command, verbose, log_error):
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        if log_error:
            logging.error(f"Command '{' '.join(command)}' failed with error: {e}")
        if verbose:
            print(f"Command '{' '.join(command)}' failed with error: {e}")
        exit(1)
    else:
        if verbose:
            print(f"Command '{' '.join(command)}' executed successfully")

def main():
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description='x86 Toolchain Script')
    parser.add_argument('filename', help='Assembly filename')
    parser.add_argument('-v', '--verbose', action='store_true', help='Show information about steps performed')
    parser.add_argument('-g', '--gdb', action='store_true', help='Run gdb command on executable')
    parser.add_argument('-b', '--breakpoint', default='_start', help='Add breakpoint after running gdb. Default is _start')
    parser.add_argument('-r', '--run', action='store_true', help='Run program in gdb automatically. Same as run command inside gdb env.')
    parser.add_argument('-q', '--qemu', action='store_true', help='Run executable in QEMU emulator. This will execute the program.')
    parser.add_argument('-64', '--x86-64', action='store_true', help='Compile for 64bit (x86-64) system.')
    parser.add_argument('-o', '--output', help='Output filename.')
    parser.add_argument('-l', '--log-error', action='store_true', help='Log errors.')

    args = parser.parse_args()

    if not args.filename:
        logging.error("Usage: x86_toolchain.py [ options ] <assembly filename> [-o | --output <output filename>]")
        parser.print_help()
        exit(1)

    output_file = args.output if args.output else args.filename.rsplit('.', 1)[0]

    if args.verbose:
        print("Arguments being set:")
        print(f"  GDB = {args.gdb}")
        print(f"  RUN = {args.run}")
        print(f"  BREAK = {args.breakpoint}")
        print(f"  QEMU = {args.qemu}")
        print(f"  Input File = {args.filename}")
        print(f"  Output File = {output_file}")
        print(f"  Verbose = {args.verbose}")
        print(f"  64 bit mode = {args.x86_64}\n")

        print("NASM started...")

    nasm_command = ["nasm", "-f", "elf64" if args.x86_64 else "elf", args.filename, "-o", f"{output_file}.o"]
    run_command(nasm_command, args.verbose, args.log_error)

    if args.verbose:
        print("NASM finished")
        print("Linking ...")

    ld_command = ["ld", "-m", "elf_x86_64" if args.x86_64 else "elf_i386", f"{output_file}.o", "-o", output_file]
    run_command(ld_command, args.verbose, args.log_error)

    if args.verbose:
        print("Linking finished")

    if args.qemu:
        print("Starting QEMU ...\n")
        qemu_command = ["qemu-x86_64" if args.x86_64 else "qemu-i386", output_file]
        run_command(qemu_command, args.verbose, args.log_error)
        exit(0)

    if args.gdb:
        gdb_params = ["gdb", "-ex", f"b {args.breakpoint}"]

        if args.run:
            gdb_params += ["-ex", "r"]

        gdb_params.append(output_file)

        run_command(gdb_params, args.verbose, args.log_error)

if __name__ == "__main__":
    main()
