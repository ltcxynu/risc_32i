# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Sun Oct 6 16:31:15 2024
# Designs open: 1
#   Sim: /home/host/risc_32i/src/rtl/coretb/simv
# Toplevel windows open: 1
# 	TopLevel.1
#   Source.1: quick_sim_core.u_rv32i.u_ex
#   Group count = 1
#   Group u_pc signal count = 22
# End_DVE_Session_Save_Info

# DVE version: O-2018.09-SP2_Full64
# DVE build date: Feb 28 2019 23:39:41


#<Session mode="Full" path="/home/host/risc_32i/src/rtl/coretb/DVEfiles/session.tcl" type="Debug">

gui_set_loading_session_type Post
gui_continuetime_set

# Close design
if { [gui_sim_state -check active] } {
    gui_sim_terminate
}
gui_close_db -all
gui_expr_clear_all

# Close all windows
gui_close_window -type Console
gui_close_window -type Wave
gui_close_window -type Source
gui_close_window -type Schematic
gui_close_window -type Data
gui_close_window -type DriverLoad
gui_close_window -type List
gui_close_window -type Memory
gui_close_window -type HSPane
gui_close_window -type DLPane
gui_close_window -type Assertion
gui_close_window -type CovHier
gui_close_window -type CoverageTable
gui_close_window -type CoverageMap
gui_close_window -type CovDetail
gui_close_window -type Local
gui_close_window -type Stack
gui_close_window -type Watch
gui_close_window -type Group
gui_close_window -type Transaction



# Application preferences
gui_set_pref_value -key app_default_font -value {Fixed [Sony],18,-1,5,50,0,0,0,0,0}
gui_src_preferences -tabstop 8 -maxbits 24 -windownumber 1
#<WindowLayout>

# DVE top-level session


# Create and position top-level window: TopLevel.1

if {![gui_exist_window -window TopLevel.1]} {
    set TopLevel.1 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.1 TopLevel.1
}
gui_show_window -window ${TopLevel.1} -show_state maximized -rect {{1 38} {2488 1573}}

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_hide_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_hide_toolbar -toolbar {CopyPaste}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_hide_toolbar -toolbar {TraceInstance}
gui_hide_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Testbench} -dock_state top
gui_set_toolbar_attributes -toolbar {Testbench} -offset 0
gui_show_toolbar -toolbar {Testbench}

# End ToolBar settings

# Docked window settings
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 283]
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
catch { set Stack.1 [gui_share_window -id ${HSPane.1} -type Stack -silent] }
catch { set Class.1 [gui_share_window -id ${HSPane.1} -type Class -silent] }
catch { set Object.1 [gui_share_window -id ${HSPane.1} -type Object -silent] }
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 283
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 282} {height 748} {dock_state left} {dock_on_new_line true} {child_hier_colhier 242} {child_hier_coltype 107} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 297]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
catch { set Local.1 [gui_share_window -id ${DLPane.1} -type Local -silent] }
catch { set Member.1 [gui_share_window -id ${DLPane.1} -type Member -silent] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 297
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 757
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 296} {height 748} {dock_state left} {dock_on_new_line true} {child_data_colvariable 251} {child_data_colvalue 52} {child_data_coltype 124} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 669]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value 658
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 669
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 657} {height 678} {dock_state bottom} {dock_on_new_line true}}
set Watch.1 [gui_create_window -type Watch -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line false -dock_extent 679]
gui_set_window_pref_key -window ${Watch.1} -key dock_width -value_type integer -value 1830
gui_set_window_pref_key -window ${Watch.1} -key dock_height -value_type integer -value 679
gui_set_window_pref_key -window ${Watch.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Watch.1} {{left 0} {top 0} {width 1829} {height 678} {dock_state bottom} {dock_on_new_line false}}
#### Start - Readjusting docked view's offset / size
set dockAreaList { top left right bottom }
foreach dockArea $dockAreaList {
  set viewList [gui_ekki_get_window_ids -active_parent -dock_area $dockArea]
  foreach view $viewList {
      if {[lsearch -exact [gui_get_window_pref_keys -window $view] dock_width] != -1} {
        set dockWidth [gui_get_window_pref_value -window $view -key dock_width]
        set dockHeight [gui_get_window_pref_value -window $view -key dock_height]
        set offset [gui_get_window_pref_value -window $view -key dock_offset]
        if { [string equal "top" $dockArea] || [string equal "bottom" $dockArea]} {
          gui_set_window_attributes -window $view -dock_offset $offset -width $dockWidth
        } else {
          gui_set_window_attributes -window $view -dock_offset $offset -height $dockHeight
        }
      }
  }
}
#### End - Readjusting docked view's offset / size
gui_sync_global -id ${TopLevel.1} -option true

# MDI window settings
set Source.1 [gui_create_window -type {Source}  -parent ${TopLevel.1}]
gui_show_window -window ${Source.1} -show_state maximized
gui_update_layout -id ${Source.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false}}

# End MDI window settings

gui_set_env TOPLEVELS::TARGET_FRAME(Source) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Schematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(PathSchematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Wave) none
gui_set_env TOPLEVELS::TARGET_FRAME(List) none
gui_set_env TOPLEVELS::TARGET_FRAME(Memory) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(DriverLoad) none
gui_update_statusbar_target_frame ${TopLevel.1}

#</WindowLayout>

#<Database>

# DVE Open design session: 

if { [llength [lindex [gui_get_db -design Sim] 0]] == 0 } {
gui_set_env SIMSETUP::SIMARGS {{}}
gui_set_env SIMSETUP::SIMEXE {./simv}
gui_set_env SIMSETUP::ALLOW_POLL {0}
if { ![gui_is_db_opened -db {/home/host/risc_32i/src/rtl/coretb/simv}] } {
gui_sim_run Ucli -exe simv -args { -ucligui} -dir /home/host/risc_32i/src/rtl/coretb -nosource
}
}
if { ![gui_sim_state -check active] } {error "Simulator did not start correctly" error}
gui_set_precision 1ns
gui_set_time_units 1ns
#</Database>

# DVE Global setting session: 


# Global: Breakpoints

# Global: Bus

# Global: Expressions

# Global: Signal Time Shift

# Global: Signal Compare

# Global: Signal Groups
gui_load_child_values {quick_sim_core.u_rv32i.u_pc}


set _session_group_1 u_pc
gui_sg_create "$_session_group_1"
set u_pc "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { quick_sim_core.u_rv32i.u_pc.pc quick_sim_core.u_rv32i.u_pc.i_p_readdata quick_sim_core.u_rv32i.u_pc.o_p_addr quick_sim_core.u_rv32i.u_pc.i_p_waitrequest quick_sim_core.u_rv32i.u_pc.inst_o quick_sim_core.u_rv32i.u_pc.pc_n quick_sim_core.u_rv32i.u_pc.jtag_reset_flag_i quick_sim_core.u_rv32i.u_pc.i_p_readdata_valid quick_sim_core.u_rv32i.u_pc.inst_addr_o quick_sim_core.u_rv32i.u_pc.hold_flag_i quick_sim_core.u_rv32i.u_pc.jmp_under_reslove quick_sim_core.u_rv32i.u_pc.o_p_writedata quick_sim_core.u_rv32i.u_pc.jump_flag_i quick_sim_core.u_rv32i.u_pc.jump_addr_i quick_sim_core.u_rv32i.u_pc.o_p_write quick_sim_core.u_rv32i.u_pc.clk quick_sim_core.u_rv32i.u_pc.o_p_byte_en quick_sim_core.u_rv32i.u_pc.o_p_read quick_sim_core.u_rv32i.u_pc.read_cache {quick_sim_core.u_rv32i.u_pc.$unit} quick_sim_core.u_rv32i.u_pc.inst_valid_o quick_sim_core.u_rv32i.u_pc.rst }

# Global: Highlighting

# Global: Stack
gui_change_stack_mode -mode list

# Global: Watch 'Watch'

gui_watch_page_delete -id Watch -all
gui_watch_page_add -id Watch
gui_watch_page_rename -id Watch -name {Watch 1}
gui_watch_list_add_expr -id Watch -expr {pc[31:0]} -meta quick_sim_core.u_rv32i.u_pc.pc -type {} -nonlocal -scope Sim:quick_sim_core.u_rv32i.u_pc.pc

gui_watch_list_add_expr -id Watch -expr {i_p_readdata[31:0]} -meta quick_sim_core.u_rv32i.u_pc.i_p_readdata -type {} -nonlocal -scope Sim:quick_sim_core.u_rv32i.u_pc.i_p_readdata

gui_watch_list_add_expr -id Watch -expr {o_p_addr[24:0]} -meta quick_sim_core.u_rv32i.u_pc.o_p_addr -type {Wire(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr i_p_waitrequest -meta quick_sim_core.u_rv32i.u_pc.i_p_waitrequest -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {inst_o[31:0]} -meta quick_sim_core.u_rv32i.u_pc.inst_o -type {Reg(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {pc_n[31:0]} -meta quick_sim_core.u_rv32i.u_pc.pc_n -type Reg -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr jtag_reset_flag_i -meta quick_sim_core.u_rv32i.u_pc.jtag_reset_flag_i -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr i_p_readdata_valid -meta quick_sim_core.u_rv32i.u_pc.i_p_readdata_valid -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {inst_addr_o[31:0]} -meta quick_sim_core.u_rv32i.u_pc.inst_addr_o -type {Reg(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {hold_flag_i[2:0]} -meta quick_sim_core.u_rv32i.u_pc.hold_flag_i -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr jmp_under_reslove -meta quick_sim_core.u_rv32i.u_pc.jmp_under_reslove -type Reg -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {o_p_writedata[31:0]} -meta quick_sim_core.u_rv32i.u_pc.o_p_writedata -type {Wire(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr jump_flag_i -meta quick_sim_core.u_rv32i.u_pc.jump_flag_i -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {jump_addr_i[31:0]} -meta quick_sim_core.u_rv32i.u_pc.jump_addr_i -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr o_p_write -meta quick_sim_core.u_rv32i.u_pc.o_p_write -type {Wire(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr clk -meta quick_sim_core.u_rv32i.u_pc.clk -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {o_p_byte_en[3:0]} -meta quick_sim_core.u_rv32i.u_pc.o_p_byte_en -type {Wire(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr o_p_read -meta quick_sim_core.u_rv32i.u_pc.o_p_read -type {Wire(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr read_cache -meta quick_sim_core.u_rv32i.u_pc.read_cache -type Reg -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr {$unit} -meta {quick_sim_core.u_rv32i.u_pc.$unit} -type {$unit} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr inst_valid_o -meta quick_sim_core.u_rv32i.u_pc.inst_valid_o -type {Reg(Port Out)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_list_add_expr -id Watch -expr rst -meta quick_sim_core.u_rv32i.u_pc.rst -type {Wire(Port In)} -nonlocal -scope quick_sim_core.u_rv32i.u_pc

gui_watch_page_add -id Watch
gui_watch_page_rename -id Watch -name {Watch 2}
gui_watch_page_add -id Watch
gui_watch_page_rename -id Watch -name {Watch 3}

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 50035



# Save global setting...

# Wave/List view global setting
gui_cov_show_value -switch false

# Close all empty TopLevel windows
foreach __top [gui_ekki_get_window_ids -type TopLevel] {
    if { [llength [gui_ekki_get_window_ids -parent $__top]] == 0} {
        gui_close_window -window $__top
    }
}
gui_set_loading_session_type noSession
# DVE View/pane content session: 


# Hier 'Hier.1'
gui_show_window -window ${Hier.1}
gui_list_set_filter -id ${Hier.1} -list { {Package 1} {All 0} {Process 1} {VirtPowSwitch 0} {UnnamedProcess 1} {UDP 0} {Function 1} {Block 1} {SrsnAndSpaCell 0} {OVA Unit 1} {LeafScCell 1} {LeafVlgCell 1} {Interface 1} {LeafVhdCell 1} {$unit 1} {NamedBlock 1} {Task 1} {VlgPackage 1} {ClassDef 1} {VirtIsoCell 0} }
gui_list_set_filter -id ${Hier.1} -text {*}
gui_hier_list_init -id ${Hier.1}
gui_change_design -id ${Hier.1} -design Sim
catch {gui_list_expand -id ${Hier.1} quick_sim_core}
catch {gui_list_expand -id ${Hier.1} quick_sim_core.u_rv32i}
catch {gui_list_select -id ${Hier.1} {quick_sim_core.u_rv32i.u_pc}}
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Class 'Class.1'
gui_list_set_filter -id ${Class.1} -list { {OVM 1} {VMM 1} {All 1} {Object 1} {UVM 1} {RVM 1} }
gui_list_set_filter -id ${Class.1} -text {*}
gui_change_design -id ${Class.1} -design Sim

# Member 'Member.1'
gui_list_set_filter -id ${Member.1} -list { {InternalMember 0} {RandMember 1} {All 0} {BaseMember 0} {PrivateMember 1} {LibBaseMember 0} {AutomaticMember 1} {VirtualMember 1} {PublicMember 1} {ProtectedMember 1} {OverRiddenMember 0} {InterfaceClassMember 1} {StaticMember 1} }
gui_list_set_filter -id ${Member.1} -text {*}

# Data 'Data.1'
gui_list_set_filter -id ${Data.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {LowPower 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Data.1} -text {*}
gui_list_show_data -id ${Data.1} {quick_sim_core.u_rv32i.u_pc}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active quick_sim_core.u_rv32i.u_ex /home/host/risc_32i/src/rtl/coretb/../core/ex.v
gui_view_scroll -id ${Source.1} -vertical -set 11368
gui_src_set_reusable -id ${Source.1}
# Warning: Class view not found.

# Watch 'Watch.1'
gui_watch_page_activate -id ${Watch.1} -page {Watch 1}
gui_list_set_filter -id ${Watch.1} -page {Watch 1} -list { {static 1} {randc 1} {public 1} {Parameter 1} {protected 1} {OtherTypes 1} {array 1} {local 1} {class 1} {AllTypes 1} {rand 1} {constraint 1} }
gui_list_set_filter -id ${Watch.1} -page {Watch 1} -text {*}
gui_watch_list_scroll_to -id ${Watch.1} -horz 0 -vert 59
gui_watch_page_activate -id ${Watch.1} -page {Watch 2}
gui_list_set_filter -id ${Watch.1} -page {Watch 2} -list { {static 1} {randc 1} {public 1} {Parameter 1} {protected 1} {OtherTypes 1} {array 1} {local 1} {class 1} {AllTypes 1} {rand 1} {constraint 1} }
gui_list_set_filter -id ${Watch.1} -page {Watch 2} -text {*}
gui_watch_page_activate -id ${Watch.1} -page {Watch 3}
gui_list_set_filter -id ${Watch.1} -page {Watch 3} -list { {static 1} {randc 1} {public 1} {Parameter 1} {protected 1} {OtherTypes 1} {array 1} {local 1} {class 1} {AllTypes 1} {rand 1} {constraint 1} }
gui_list_set_filter -id ${Watch.1} -page {Watch 3} -text {*}
gui_watch_page_activate -id ${Watch.1} -page {Watch 1}
gui_view_scroll -id ${Watch.1} -vertical -set 59
gui_view_scroll -id ${Watch.1} -horizontal -set 0
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${TopLevel.1}]} {
	gui_set_active_window -window ${TopLevel.1}
	gui_set_active_window -window ${Source.1}
	gui_set_active_window -window ${Console.1}
}
#</Session>

