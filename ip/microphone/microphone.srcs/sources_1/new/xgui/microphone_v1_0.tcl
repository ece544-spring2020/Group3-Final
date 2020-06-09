# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "AUD_SAMPLE_FREQ_HZ" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SYSCLK_FREQ_MHZ" -parent ${Page_0}


}

proc update_PARAM_VALUE.AUD_SAMPLE_FREQ_HZ { PARAM_VALUE.AUD_SAMPLE_FREQ_HZ } {
	# Procedure called to update AUD_SAMPLE_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AUD_SAMPLE_FREQ_HZ { PARAM_VALUE.AUD_SAMPLE_FREQ_HZ } {
	# Procedure called to validate AUD_SAMPLE_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.PACKET_SIZE { PARAM_VALUE.PACKET_SIZE } {
	# Procedure called to update PACKET_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PACKET_SIZE { PARAM_VALUE.PACKET_SIZE } {
	# Procedure called to validate PACKET_SIZE
	return true
}

proc update_PARAM_VALUE.SYSCLK_FREQ_MHZ { PARAM_VALUE.SYSCLK_FREQ_MHZ } {
	# Procedure called to update SYSCLK_FREQ_MHZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYSCLK_FREQ_MHZ { PARAM_VALUE.SYSCLK_FREQ_MHZ } {
	# Procedure called to validate SYSCLK_FREQ_MHZ
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.AUD_SAMPLE_FREQ_HZ { MODELPARAM_VALUE.AUD_SAMPLE_FREQ_HZ PARAM_VALUE.AUD_SAMPLE_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AUD_SAMPLE_FREQ_HZ}] ${MODELPARAM_VALUE.AUD_SAMPLE_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.SYSCLK_FREQ_MHZ { MODELPARAM_VALUE.SYSCLK_FREQ_MHZ PARAM_VALUE.SYSCLK_FREQ_MHZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYSCLK_FREQ_MHZ}] ${MODELPARAM_VALUE.SYSCLK_FREQ_MHZ}
}

proc update_MODELPARAM_VALUE.PACKET_SIZE { MODELPARAM_VALUE.PACKET_SIZE PARAM_VALUE.PACKET_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PACKET_SIZE}] ${MODELPARAM_VALUE.PACKET_SIZE}
}

