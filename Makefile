# --- HW Paths ---
HW_DIR = hw
WILDCAT_DIR = wildcat
GENERATED_DIR = $(WILDCAT_DIR)/generated
BUILD_DIR = $(HW_DIR)/vivado
BIN_FILE = $(BUILD_DIR)/system.runs/impl_1/RustSoCTop.bin
V_FILE = $(GENERATED_DIR)/RustSoCTop.v

# --- Rust paths ---
RUST_DIR = sw/program
RUST_TARGET = riscv32i-unknown-none-elf
RUST_RELEASE = $(RUST_DIR)/target/$(RUST_TARGET)/release

# --- Loader ---
LOADER = sw/loader/upload.py
SERIAL_PORT ?= COM5

# --- Tools ---
# vivado in system PATH.
VIVADO = vivado -mode batch -notrace
SBT = sbt

# --- Cross-platform OS detection ---
ifdef OS
# Windows_NT (default in windows environment variables)
	RM = del /Q
	RMDIR = rmdir /S /Q
# Macro to convert slashes to backslahes for Windows commands
	FIXPATH = $(subst /,\,$1)
# Run a command through WSL (needed for Linux-only tools like riscv64-unknown-elf-gcc)
	WSL = wsl
else
# Linux / macOS
	RM = rm -f
	RMDIR = rm -rf
	FIXPATH = $1
	WSL =
endif

.PHONY: all build flash clean generate-verilog rust-build upload hw-test sim-test risc-v-lab

all: build

# ────────────────────────────────────────────────
#  HW compilation
# ────────────────────────────────────────────────

# File target - Generates verilog from Chisel (RustSoCTop)
$(V_FILE):
	cd $(WILDCAT_DIR) && $(SBT) "runMain rvsoc.RustSoCTopGen"

# File target - Regenerates bitstream if verilog sources change
$(BIN_FILE): $(V_FILE)
	$(VIVADO) -source $(HW_DIR)/scripts/build.tcl

# Results in target $(BIN_FILE) executes.
build: $(BIN_FILE)

# Flash the Board (and generates all necessary files)
flash: $(BIN_FILE)
	$(VIVADO) -source $(HW_DIR)/scripts/flash.tcl -tclargs "$(BIN_FILE)"

# ────────────────────────────────────────────────
#  Rust compilation
# ────────────────────────────────────────────────

# Cargo to compile rust to binary. Cargo has built in check, so only recompiles if necessary
rust-build:
	cd $(RUST_DIR) && cargo build --target $(RUST_TARGET) --release
	cd $(RUST_DIR) && cargo objcopy --target $(RUST_TARGET) --release -- -O binary target/$(RUST_TARGET)/release/program.bin

# Show the RiscV32i instructions in terminal
rust-disassemble:
	rust-objdump -d $(RUST_RELEASE)/program

# ────────────────────────────────────────────────
#  Upload & test via UART
# ────────────────────────────────────────────────

# Upload a binary to the FPGA and listen for output
upload: rust-build
	python $(LOADER) --port $(SERIAL_PORT) --binary $(RUST_RELEASE)/program.bin --listen 5

# Upload and listen for expected UART output (for CI / test automation)
hw-test: rust-build
	python $(LOADER) --port $(SERIAL_PORT) --binary $(RUST_RELEASE)/program.bin --expect "PASS" --timeout 10

# ────────────────────────────────────────────────
#  Simulation tests (in terminal)
# ────────────────────────────────────────────────

# Clone the risc-v-lab test vectors and compile them.
# Uses WSL on Windows since riscv64 binutils is a Linux-native tool.
# On Linux/CI the toolchain must be installed: apt-get install binutils-riscv64-linux-gnu
$(WILDCAT_DIR)/risc-v-lab:
	cd $(WILDCAT_DIR) && git clone https://github.com/schoeberl/risc-v-lab.git
	$(WSL) make -C $(WILDCAT_DIR)/risc-v-lab/tests/simple

# Run all Wildcat simulation tests
# On first run this clones risc-v-lab and compiles the test binaries.
sim-test: $(WILDCAT_DIR)/risc-v-lab
	cd $(WILDCAT_DIR) && $(SBT) test

# ────────────────────────────────────────────────
#  Clean
# ────────────────────────────────────────────────

clean:
# '-' make sure the script continues even if folders doesn't exist
	-$(RMDIR) $(call FIXPATH, $(BUILD_DIR))
	-$(RMDIR) $(call FIXPATH, $(GENERATED_DIR))
	-$(RMDIR) $(call FIXPATH, .Xil)
	-$(RM) $(call FIXPATH, *.log)
	-$(RM) $(call FIXPATH, *.jou)