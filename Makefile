#Makefile 
RTL = ../rtl/*.v
LIB = router_top
COVOP = -coveropt 3 +cover +acc
TB = ../tb/*.v
VSIMOPT = -coverage -vopt router_top.router_top_tb
VSIMCOV = coverage save -onexit -codeAll router_topcov 
VSIMBATCH = -c -do "$(VSIMCOV); run -all; exit" 



lib:
	vlib $(LIB)
	vmap work $(LIB)
help:
	@echo ===========================================================================================================================
	@echo " USAGE   	--  make target"
	@echo " clean   	=>  clean the earlier log and intermediate files."
	@echo " lib             =>  Create library and logical mapping."									   
	@echo " run_tb        	=>  To compile RTL, TB & simulate the RTL using TB in batch mode." 
	@echo " run       	=>  To clean, create libray, logical mapping, compile the source codes & simulate the RTL in batch mode."        
	@echo " html       	=>  To display html report using browser"        
	@echo " report       	=>  To create the html coverage report from the coverage database file"        
	@echo ===========================================================================================================================


run_tb:
	vlog -work router_top $(COVOP) $(RTL) $(TB)
	vsim $(VSIMOPT) $(VSIMBATCH) 

report:
	vcover report  -details -codeAll -html router_topcov

html:
	firefox covhtmlreport/index.html&
	
run: clean lib run_tb report  html

clean:
	rm -rf modelsim.ini transcript cov*  router_topcov
	rm -rf $(LIB)
	clear


