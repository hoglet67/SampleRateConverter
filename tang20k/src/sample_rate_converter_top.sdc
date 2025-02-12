create_clock -name sys_clk -period 37.037 -waveform {0 18.518} [get_ports {sys_clk}] -add

create_generated_clock -name clk48 -source [get_ports {sys_clk}] -master_clock sys_clk -divide_by 27 -multiply_by 48 [get_nets {clk48}]

set_operating_conditions -grade c -model slow -speed 8 -setup -hold
