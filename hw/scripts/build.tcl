# Define output directory
set outputDir ./hw/vivado
file mkdir $outputDir

# Setup project (Generic name "system")
create_project -force system $outputDir -part xc7a35tcpg236-1

# Add source files
add_files [glob ./hw/src/*.v]
add_files -fileset constrs_1 ./hw/constraints/basys3.xdc

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

puts "Build Complete! Bitstream is in $outputDir/system.runs/impl_1/top.bin"