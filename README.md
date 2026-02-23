# rust-riscv-soc
Allows you to run rust code on your FPGA through a Wildcat Risc-V


## Prerequisites & Installation
To run this project, you need to install the following tools.

### 1. Xilinx Vivado (WebPACK Edition)
Required for synthesizing the hardware and flashing the FPGA.

- **Download:** Xilinx Unified Installer
- **Install:** Select "Vivado Standard" or "WebPACK" (Free).
- **Important:** During installation, ensure you install the Cable Drivers.
- **System PATH:** After installation, you must add the Vivado bin folder to your system PATH so the terminal can  find the *vivado* command.
    - *Windows:* Add C:\Xilinx\Vivado\20xx.x\bin to Environment Variables -> Path.
    - *Linux/Mac:* Add source /tools/Xilinx/Vivado/20xx.x/settings64.sh to your .bashrc or .zshrc.
### 2. Make (Build Tool)
Required to run the automation scripts.

- Windows:
    - Option A (Recommended): Install via Chocolatey. Open PowerShell as Admin and run: choco install make
    - Option B: Download GnuWin32 Make, install it, and add C:\Program Files (x86)\GnuWin32\bin to your PATH.
- macOS:
    - Open Terminal and run: xcode-select --install
- Linux:
    - Ubuntu/Debian: sudo apt install make
    - Fedora: sudo dnf install make
### 3. RISC-V Toolchain (GCC)
Required to compile C/Rust code for the processor.

- Windows:
    - Download the xPack RISC-V Embedded GCC.
    - Extract it and add the bin folder to your PATH.
- macOS:
    - brew tap riscv-software-src/riscv
    - brew install riscv-tools
- Linux:
    - Ubuntu: sudo apt install gcc-riscv64-unknown-elf
### 4. Python 3
Required for the UART upload script.

- Windows/Mac/Linux: Download from python.org.
- Dependencies: Install the serial library:
```bash
pip install pyserial
```
### 5. Git
Required for version control and downloading the processor core.

- Download: git-scm.com

## :rocket: Getting started
For now a simple blink program counts binary with the 16 LEDs on the basys3 board.

### 1. Clone repo
```bash
git clone https://github.com/Jfvind/rust-riscv-soc
cd rust-riscv-soc
```
### 2. Flash
Build top.bin from hw/src/top.v and flash to Basys3
- **Dependency:** Make sure Basys3 is connected and turned on (And 'Prerequisites & Installation' is completed)
```bash
make flash
```
- **Duration:** 3 minutes to a lifetime :skull:
- **Output:** 
    - Makes a Vivado project at hw/vivado
    - Generates .jou and .log in root
    - Generates /.Xil in root
- *Note*: it is possible to only build the .bin and .bit files using *make build*, this doesn't flash the FPGA memory.

### :arrow_forward: 3. PROG
Press the red button in top right corner of the Basys3.
After 5-10 seconds you program should be running on the FPGA, stores in the non-volatile memory.

### :broom: 4. Clean up (Optional)
Since the program is stored in the flash memory, the generated files are not necessary.
**Note:** if making changes to the top.v and the hw/vivado is cleaned away, then *make flash* will take longer (~1 min)