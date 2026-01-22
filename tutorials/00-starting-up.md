# 00: Starting up

Log-in to the RHEL server and make an empty folder in your home:

```bash
cd ~
mkdir Work
cd ~/Work
```

Clone this repository inside the Work folder:

```bash
git clone https://github.com/jmonrods/uvmcc
```

Navigate to the repo:

```bash
cd uvmcc
```

Review what's in the Makefile:

```bash
cat Makefile
```

Source the startup file for Siemens tools:

```bash
source ~/start_mentor.sh
```

And run the directed testbench:

```bash
make cpu_tb
```

