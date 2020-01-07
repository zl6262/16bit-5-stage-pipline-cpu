	`include"define.v"
	module id_ex(
	input wire clk,
	input wire rst,
	input wire[5:0]			stall,
	//前一阶段（译码阶段）传递过来的信息
	input wire[`AluOpBus]	id_aluop,  
	input wire[`AluSelBus]	id_alusel,
	input wire[`RegBus]		id_reg1,
	input wire[`RegBus]		id_reg2,
	input wire[`RegAddrBus]	id_wd,      //要写入的寄存器的地址
	input wire  				id_wreg,   //译码阶段的指令是否有要写入的目的寄存器
	input wire 					id_flag_upd,
	
	input wire 					id_is_in_delayslot,		//当前处于译码阶段的指令是否位于延迟槽
	input wire[`RegBus]		id_link_address,		//处于译码阶段的转移指令要保存的返回地址
	input wire					next_inst_in_delayslot_i,//下一条进入译码阶段的指令是否位于延迟槽
	output reg					ex_is_in_delayslot,		//当前处于执行阶段的指令是否位于延迟槽
	output reg[`RegBus]		ex_link_address,			//处于执行阶段的转移指令要保存的返回地址
	output reg 					is_in_delayslot_o,		//当前位于译码阶段的指令是否位于延迟槽
	//传递到执行阶段的信息
	output reg[`AluOpBus]	ex_aluop,
	output reg[`AluSelBus]	ex_alusel,
	output reg[`RegBus]		ex_reg1,
	output reg[`RegBus]		ex_reg2,
	output reg[`RegAddrBus]	ex_wd,
	output reg					ex_wreg,
	output reg 					ex_flag_upd
);
// 当stall[2]为stop stall[3] Nostop 表示译码暂停
//		执行阶段继续，所以使用空指令nop进入下一周期
//	stall[2] nostop时，译码继续，指令进入执行阶段
//	其余阶段保持ex_inst不变

always @(posedge clk)	begin
	if(rst == `RstEnable)	begin
		ex_aluop	<=	`EXE_NOP_OP;
		ex_alusel<=	`EXE_RES_NOP;
		ex_reg1	<=	`ZeroHalfWord;
		ex_reg2	<=	`ZeroHalfWord;
		ex_wd		<=	`NOPRegAddr;
		ex_wreg	<=	`WriteDisable;
		ex_flag_upd<=	`NoFlagUpd;
		end
	else if(stall[2]==`Stop&&stall[3]==`NoStop)begin
		ex_aluop	<=`EXE_NOP_OP;
		ex_alusel<=`EXE_RES_NOP;
		ex_reg1	<=`ZeroHalfWord;
		ex_reg2	<=`ZeroHalfWord;
		ex_wd		<=`NOPRegAddr;
		ex_wreg	<=`WriteDisable;
		end
	else if(stall[2]==`NoStop)begin
		ex_aluop	<=	id_aluop;
		ex_alusel<=	id_alusel;
		ex_reg1	<=	id_reg1;
		ex_reg2	<=	id_reg2;
		ex_wd		<=	id_wd;
		ex_wreg	<=	id_wreg;
		ex_flag_upd<=id_flag_upd;
		
		ex_link_address	<=	id_link_address;
		ex_is_in_delayslot<=id_is_in_delayslot;
		is_in_delayslot_o<=	next_inst_in_delayslot_i; //当前处于译码阶段的指令是否处于译码阶段
		end
end


endmodule 