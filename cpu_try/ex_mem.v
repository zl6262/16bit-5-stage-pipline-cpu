`include"define.v"
module ex_mem(
	input wire	clk,
	input wire	rst,
	input wire[5:0]			stall,
// 来自执行阶段的信息
	input	wire[`RegAddrBus]	ex_wd,
	input wire					ex_wreg,
	input wire[`RegBus]		ex_wdata,
	input wire[`RegBus]		ex_hi,
	input wire[`RegBus]		ex_lo,
	input wire					ex_whilo,
	input wire[`AluOpBus]	ex_aluop,
	input wire[`RegBus]		ex_mem_addr,
	input wire[`RegBus]		ex_data_store,
// 送到访存阶段的信息
	output reg[`RegAddrBus]	mem_wd,
	output reg					mem_wreg,
	output reg[`RegBus]		mem_wdata,
	output reg[`RegBus]		mem_hi,
	output reg[`RegBus]		mem_lo,
	output reg					mem_whilo,
	output reg[`AluOpBus]	mem_aluop,
	output reg[`RegBus]		mem_mem_addr,
	output reg[`RegBus]		mem_data_store
);
// 当stall[3]为stop，stop[4] nostop时，表示执行阶段暂停
//		而访存阶段继续，所以采用空指令作为下一周期进入访存阶段的指令
//	stall[3]为nostop	，执行阶段继续，执行后的指令进入访存阶段
//  其余情况，保持 输出信号不变
always@(posedge clk)	begin
	if(rst==`RstEnable)	begin
		mem_wd	<=	`NOPRegAddr;
		mem_wreg	<=	`WriteDisable;
		mem_wdata<=	`ZeroHalfWord;
		mem_hi	<=`ZeroHalfWord;
		mem_lo	<=`ZeroHalfWord;
		mem_whilo<=`WriteDisable;
		mem_aluop<=`EXE_NOP_OP;
		mem_mem_addr<=`ZeroHalfWord;
		mem_data_store<=`ZeroHalfWord;
		end
	else if(stall[3]==`Stop&& stall[4]==`NoStop)begin
		mem_wd	<=`NOPRegAddr;
		mem_wreg	<=`WriteDisable;
		mem_wdata<=`ZeroHalfWord;
		mem_hi	<=`ZeroHalfWord;
		mem_lo	<=`ZeroHalfWord;
		mem_whilo<=`WriteDisable;
		mem_aluop<=`EXE_NOP_OP;
		mem_mem_addr<=`ZeroHalfWord;
		mem_data_store<=`ZeroHalfWord;
		end
	else if(stall[3]==`NoStop)begin
		mem_wd	<=	ex_wd;
		mem_wreg	<=	ex_wreg;
		mem_wdata<=	ex_wdata;
		mem_hi	<=	ex_hi;
		mem_lo	<=	ex_lo;
		mem_whilo<=	ex_whilo;
		mem_aluop<=	ex_aluop;
		mem_mem_addr<=	ex_mem_addr;
		mem_data_store<= ex_data_store;
		end
end 


endmodule 