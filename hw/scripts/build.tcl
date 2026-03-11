# Generate output directory (git ignored)
set outputDir ./hw/vivado
file mkdir $outputDir

# Setup project (name is "system")
create_project -force system $outputDir -part xc7a35tcpg236-1

# Add Wildcat verilog and constraints
add_files [glob ./wildcat/generated/*.v]
add_files -fileset constrs_1 ./hw/constraints/basys3.xdc

# Copy hex files (data0 - data3) so Vivado can find them for $readmemh.
foreach f [glob -nocomplain ./wildcat/data*.hex] {
    file copy -force $f $outputDir/
    file copy -force $f .
}

# Set top module to RustSoCTop
set_property top RustSoCTop [current_fileset]

# Run Synthesis
puts "Running Synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Run Implementation
puts "Running Implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Generate Bitstream and BIN file
puts "Generating Bitstream..."
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

puts "Build Complete! Bitstream is in $outputDir/system.runs/impl_1/RustSoCTop.bin"