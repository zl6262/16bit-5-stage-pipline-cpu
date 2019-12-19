`include"define.v"
module mem_wb(
	input wire		clk,
	input wire		rst,
	input wire[5:0]	stall,
//访存阶段的结果
	input wire[`RegAddrBus]		mem_wd,
	input wire						mem_wreg,
	input wire[`RegBus]			mem_wdata,
	input wire[`RegBus]			mem_hi,
	input wire[`RegBus]			mem_lo,
	input wire 						mem_whilo,
//送到回写阶段的信息
	output reg[`RegAddrBus]		wb_wd,
	output reg						wb_wreg,
	output reg[`RegBus]			wb_wdata,
	output reg[`RegBus]			wb_hi,
	output reg[`RegBus]			wb_lo,
	output reg						wb_whilo
);

//stall[4]为Stop，stall[5]为nostop时，表示访存暂停
// 		回写阶段继续，用空指令作为下一周期进入回写阶段的指令
// srall[4]为nostop时，访存继续，访存后的指令进入回写阶段
// 其他情况，保持回写阶段的寄存器输出不变
always@(posedge clk)	begin
	if(rst==`RstEnable)	begin
		wb_wd		<=		`NOPRegAddr;
		wb_wreg	<=		`WriteDisable;
		wb_wdata	<=		`ZeroHalfWord;
		wb_hi		<=		`ZeroHalfWord;
		wb_lo		<=		`ZeroHalfWord;
		wb_whilo	<=		`WriteDisable;
			end
	else if(stall[4]==`Stop&&stall[5]==`NoStop)	begin
		wb_wd		<=		`NOPRegAddr;
		wb_wreg	<=		`WriteDisable;
		wb_wdata	<=		`ZeroHalfWord;
		wb_hi		<=		`ZeroHalfWord;
		wb_lo		<=		`ZeroHalfWord;
		wb_whilo	<=		`WriteDisable;
			end
	else if(stall[4]==`NoStop)begin
		wb_wd		<=		mem_wd;
		wb_wreg	<=		mem_wreg;
		wb_wdata	<=		mem_wdata;
		wb_hi		<=		mem_hi;
		wb_lo		<=		mem_lo;
		wb_whilo	<=		mem_whilo;
		end
end
endmodule 