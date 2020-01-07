`include"define.v"
module top_test(
	input clk,
	input rst
);

	wire[`InstAddrBus]	inst_addr;
	wire[`InstBus]			inst;
	wire						rom_we;
	wire	c,z,v,s;				
	cpu_try 	cpu_try0(
	.clk(clk),	.rst(rst),
	.ram_addr_o(inst_addr),	.ram_data_i(inst),
	.ram_we_o(rom_we)	,.c(c), .z(z), .v(v), .s(s)
	);
	inst_rom	inst_rom0(
	.we(rom_we),	.addr(inst_addr),	.inst(inst)
	);
endmodule 