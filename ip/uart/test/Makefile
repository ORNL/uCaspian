test: uart_tb.pass uart_tb_2.pass uart_rx_tb.pass uart_tx_tb.pass

%.vvp: %.sv
	iverilog -g2012 -y../src -y. -Y.sv -o $@ $^
%.pass: %.vvp
	vvp -N $<
clean:
	-$(RM) *.vvp *.vcd *.pass
