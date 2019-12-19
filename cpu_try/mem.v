`include"define.v"
module mem(
	input	wire	rst,
//来自执行阶段的信息	
	input wire[`RegAddrBus]	wd_i,
	input wire					wreg_i,
	input wire[`RegBus]		wdata_i,
	input wire[`RegBus]		hi_i,
	input wire[`RegBus]		lo_i,
	input wire 					whilo_i,
	input wire[`AluOpBus]	aluop_i,
	//
	input wire[`RegBus]		mem_addr_i,
	input wire[`RegBus]		mem_data_store,//需要store的数据
	//load 的数据
	input wire[`RegBus]		mem_data_i,
//访存阶段的结果
	output reg[`RegAddrBus]	wd_o,
	output reg					wreg_o,
	output reg[`RegBus]		wdata_o,
	output reg[`RegBus]		hi_o,
	output reg[`RegBus]		lo_o,
	output reg					whilo_o,
	///////////////////////////////////
	output reg[`RegBus]		mem_addr_o,
	output reg[`RegBus]		mem_data_o,//访存输出的数据
	output reg[1:0]			wr_Mem
);

always@(*)	begin
	if(rst == `RstEnable)	begin
		wd_o		<=	`NOPRegAddr;
		wreg_o	<=	`WriteDisable;
		wdata_o	<=	`ZeroHalfWord;
		hi_o		<=	`ZeroHalfWord;
		lo_o		<=	`ZeroHalfWord;
		whilo_o		<=	`WriteDisable;
		//ram
		mem_addr_o	<=	`ZeroHalfWord;
		mem_data_o	<=	`ZeroHalfWord;
		wr_Mem		<= 2'b11;
			end
	else	begin
		wd_o		<=	wd_i;
		wreg_o	<=	wreg_i;
		wdata_o	<=	wdata_i;
		hi_o		<=	hi_i;
		lo_o		<=	lo_i;
		whilo_o	<=	whilo_i;
		mem_data_o<=`ZeroHalfWord;
		mem_addr_o<=`ZeroHalfWord;
		wr_Mem	<=	2'b11;
			case(aluop_i)
				`EXE_LOAD_OP:begin
						mem_addr_o	<=	mem_addr_o;
						wr_Mem		<=2'b00;
						wdata_o		<=	mem_data_i;
					end
				`EXE_STORE_OP:begin
						mem_addr_o	<=	mem_addr_i;
						wr_Mem		<= 2'b01;
						mem_data_o	<=	mem_data_store;
			end
			endcase
end
end
endmodule	