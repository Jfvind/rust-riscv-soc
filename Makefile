# --- Paths ---
HW_DIR = hw
BUILD_DIR = $(HW_DIR)/vivado
BIN_FILE = $(BUILD_DIR)/system.runs/impl_1/top.bin

# --- Tools ---
# 'vivado' should be in system PATH.
VIVADO = vivado -mode batch -notrace

# --- Cross-platform OS detection ---
ifdef OS
# Windows_NT (default in windows environment variables)
	RM = del /Q
	RMDIR = rmdir /S /Q
# Macro to convert slashes to backslahes for Windows commands
	FIXPATH = $(subst /,\,$1)
else
# Linux / macOS
	RM = rm -f
	RMDIR = rm -rf
	FIXPATH = $1
endif

.PHONY: all build flash clean

all: build

# File target - Executes if top.v is newer than top.bin (resynthesis of top.bin).
$(BIN_FILE): $(HW_DIR)/src/top.v
	$(VIVADO) -source $(HW_DIR)/scripts/build.tcl

# Phony target - "make build" results in target $(BIN_FILE) executes.
build: $(BIN_FILE)

# Flash the Board - Checks is top.v has been updated since last synthesis (reruns if necessary) and then flashes
flash: $(BIN_FILE)
	$(VIVADO) -source $(HW_DIR)/scripts/flash.tcl -tclargs "$(BIN_FILE)"

# Clean up build files
clean:
# '-' make sure the script continues even if folders doesn't exist
	-$(RMDIR) $(call FIXPATH, $(BUILD_DIR))
	-$(RMDIR) $(call FIXPATH, .Xil)
	-$(RM) $(call FIXPATH, *.log)
	-$(RM) $(call FIXPATH, *.jou)