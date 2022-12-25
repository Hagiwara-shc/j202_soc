# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

# Base Configurations. Don't Touch
# section begin

set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

# YOU ARE NOT ALLOWED TO CHANGE ANY VARIABLES DEFINED IN THE FIXED WRAPPER CFGS 
source $::env(DESIGN_DIR)/fixed_dont_change/fixed_wrapper_cfgs.tcl

# YOU CAN CHANGE ANY VARIABLES DEFINED IN THE DEFAULT WRAPPER CFGS BY OVERRIDING THEM IN THIS CONFIG.TCL
source $::env(DESIGN_DIR)/fixed_dont_change/default_wrapper_cfgs.tcl

#set script_dir [file dirname [file normalize [info script]]]
set script_dir $::env(DESIGN_DIR)

set ::env(DESIGN_NAME) user_project_wrapper
#section end

# User Configurations

# save some time
set ::env(RUN_KLAYOUT_XOR) 0
set ::env(RUN_KLAYOUT_DRC) 0
# no point in running DRC with magic once openram is in because it will find 3M issues
# try to turn off all DRC checking so the flow completes and use precheck for DRC instead.
set ::env(MAGIC_DRC_USE_GDS) 0
set ::env(RUN_MAGIC_DRC) 0
set ::env(QUIT_ON_MAGIC_DRC) 0

set ::env(ROUTING_CORES) 4

# Define
set ::env(SYNTH_DEFINES) "J202_SOC_CORE_EMPTY"

## Source Verilog Files
set ::env(VERILOG_FILES) "\
	$::env(CARAVEL_ROOT)/verilog/rtl/defines.v \
	$::env(CARAVEL_ROOT)/../verilog/rtl/user_project_wrapper.v"

## Clock configurations
set ::env(CLOCK_PORT) "wb_clk_i"

set ::env(CLOCK_PERIOD) "20"
#set ::env(BASE_SDC_FILE) $script_dir/base.sdc

### PDN
set ::env(PDN_CFG) $script_dir/pdn_cfg.tcl
set ::env(VDD_PIN) {vccd1}
set ::env(GND_PIN) {vssd1}
set ::env(FP_PDN_HPITCH) 180
set ::env(FP_PDN_HOFFSET) 50

## Internal Macros
### Macro PDN Connections
set ::env(FP_PDN_MACRO_HOOKS) "\
	j202_soc_core_wrapper vccd1 vssd1 vccd1 vssd1"

### Macro Placement
set ::env(MACRO_PLACEMENT_CFG) $script_dir/macro.cfg

### Black-box verilog and views
set ::env(VERILOG_FILES_BLACKBOX) "\
	$::env(CARAVEL_ROOT)/verilog/rtl/defines.v \
  $::env(CARAVEL_ROOT)/../verilog/rtl/j202_soc/j202_soc_core/j202_soc_core_wrapper.v"

set ::env(EXTRA_LEFS) "\
	$::env(CARAVEL_ROOT)/../lef/j202_soc_core_wrapper_del_met5.lef"

set ::env(EXTRA_GDS_FILES) "\
	$::env(CARAVEL_ROOT)/../gds/j202_soc_core_wrapper.gds"

# set ::env(GLB_RT_MAXLAYER) 5
set ::env(RT_MAX_LAYER) {met4}

#set ::env(GLB_RT_ALLOW_CONGESTION) 1

# disable pdn check nodes becuase it hangs with multiple power domains.
# any issue with pdn connections will be flagged with LVS so it is not a critical check.
set ::env(FP_PDN_CHECK_NODES) 0

# The following is because there are no std cells in the example wrapper project.
set ::env(PL_RANDOM_GLB_PLACEMENT) 1

set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 0
set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 0

set ::env(FP_PDN_ENABLE_RAILS) 0

set ::env(DIODE_INSERTION_STRATEGY) 0
set ::env(FILL_INSERTION) 0
set ::env(TAP_DECAP_INSERTION) 0
set ::env(CLOCK_TREE_SYNTH) 0

set ::env(CELL_PAD) 4

