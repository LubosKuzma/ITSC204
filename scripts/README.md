# Prerquisites for x86_toolchain.sh:

### GDB:
Install GDB
```
sudo apt-get update && sudo apt-get install gdb
```

### GEF:
Install GEF
```
# via the install script
## using curl
$ bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

## using wget
$ bash -c "$(wget https://gef.blah.cat/sh -O -)"

# or manually
$ wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/py
$ echo source ~/.gdbinit-gef.py >> ~/.gdbinit

# or alternatively from inside gdb directly
$ gdb -q
(gdb) pi import urllib.request as u, tempfile as t; g=t.NamedTemporaryFile(suffix='-gef.py'); open(g.name, 'wb+').write(u.urlopen('https://tinyurl.com/gef-main').read()); gdb.execute('source %s' % g.name)
```
(Taken from https://github.com/hugsy/gef)

### PATH:
add toolchain script to PATH:
```
echo 'export PATH=$PATH:~/ITSC204/scripts' >> ~/.bashrc
```

### QEMU:
Install QEMU:
```
sudo apt install qemu-user
```

# Prerequisites for arm_toolchain.sh:

### GCC
Install ARM GCC:
```
apt-get install gcc-arm-linux-gnueabihf
```

### GDB-Multiarch
Install Multiarchitecture GDB
```
apt-get install gdb-multiarch
```
