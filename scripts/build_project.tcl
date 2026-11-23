# ==============================================================================
# Master Vivado Project Recreation Script
# Target: Digilent Arty Z7-20 (xc7z020clg400-1)
# Tool:   Vivado 2022.2
# Usage:  vivado -mode batch -source scripts/build_project.tcl
# ==============================================================================

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize "$script_dir/.."]
set proj_name  "UART_RX_TX_LIFO"
set proj_dir   "$repo_root/vivado_proj"

# Create project directory and Vivado project
file mkdir $proj_dir
create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

# Set Arty Z7-20 board part if installed in local Vivado board store
set board_parts [get_board_parts -quiet digilentinc.com:arty-z7-20:part0:*]
if { [llength $board_parts] > 0 } {
    set_property board_part [lindex $board_parts end] [current_project]
}

# Add synthesizable RTL sources
add_files -fileset sources_1 [list \
    "$repo_root/rtl/LIFO.vhd" \
    "$repo_root/rtl/UART_RX.vhd" \
    "$repo_root/rtl/UART_TX.vhd" \
    "$repo_root/rtl/UART_RX_TX_LIFO_TOP.vhd" \
]

# Add simulation testbenches
add_files -fileset sim_1 [list \
    "$repo_root/tb/LIFO_testbench.vhd" \
    "$repo_root/tb/RX_Testbench.vhd" \
]
set_property top RX_Testbench [get_filesets sim_1]

# Add physical constraints
add_files -fileset constrs_1 "$repo_root/constraints/Arty-Z7-20-Master.xdc"

# Update compile order so RTL modules can be referenced in IP Integrator
update_compile_order -fileset sources_1

# Build and validate the Zynq PS7 + PL Block Design
source "$script_dir/design_1.tcl"

# Generate top-level HDL wrapper and set as synthesis top
set bd_file [get_files design_1.bd]
set wrapper_file [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_file
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: Vivado project successfully created at $proj_dir/$proj_name.xpr"
