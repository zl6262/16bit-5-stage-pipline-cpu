/*if_id暂时保存取指阶段获得的指令，以及对应的指令地址，并在下一个时钟传递到译码阶段
*/
`include"define.v"
module if_id(
	input wire clk,
	input wire rst,
	input wire[5:0] stall,
	input wire [`InstAddrBus] if_pc,    //InstAddrBus 为地址总线宽度 
	inout wire [`InstBus]     if_inst,  //InstBus为指令总线的宽度  此为输入的数据
	output wire [`InstAddrBus]	ram_addr_o,
	output reg [`InstAddrBus] id_pc,
	output reg [`InstBus]     id_inst,
	/*
	待增加信号 we 写信号
	增加要写的数据 alu_out
				//根据指令类型 更改we
	*/
	input wire[1:0]			wr_Mem,
	input wire[`RegBus]		mem_addr_i,
	input wire[`RegBus]		mem_data_i,  //store
	output wire[`RegBus]		mem_data_o,	 //load
	input wire 					we
	);
reg[`InstBus]	mem_data_in;
wire[`InstBus]	mem_data_out;
assign mem_data_out = mem_data_i;
assign mem_data_o = (wr_Mem==2'b00)? if_inst:16'h0000;
assign if_inst =(we==`ChipRead)?	16'hzzzz:	mem_data_i;
//always@(posedge clk)	begin
//		if(wr_Mem[1]==1'b1)	begin
//			ram_addr_o	<= if_pc;
//			end
//		else 	begin
//			ram_addr_o	<=mem_addr_i;
//			end
//end

assign ram_addr_o	=(wr_Mem[1]==1'b1) ? if_pc: mem_addr_i;
always@(*)	begin
		if(wr_Mem==2'b00)begin //load
	//	mem_data_o<=if_inst;
		mem_data_in<= `EXE_NOP_OP;
		end
		else if(wr_Mem==2'b01)begin
//		mem_data_out<=mem_data_i;	
		mem_data_in<=`EXE_NOP_OP;
		end
		else 	begin
		mem_data_in <=if_inst;
		end
		
end
		
//always@(*)	begin
//	if(we==`ChipRead)	begin	
//			
//			end
//	else if(we==`ChipWrite)	begin
//		//	wr_mem_data  用alu运算结果更新mem_data_out;
//			end
//end

// stall[1]为stop ，stall[2]nostop 则为取指阶段暂停
//	stall[1] nostop  取指阶段继续，取得指令进入译码阶段
//	其余情况保持译码阶段的 	id_pc,id_inst不变。



always@(posedge clk)
begin 
	if(rst==`RstEnable)
		begin
		id_pc<=`ZeroHalfWord; //复位时pc为0
//		id_inst<={`INST_4,`EXE_NOP,8'h00}; //复位时候指令为0 空指令
		end
	else if((stall[1]==`Stop&&stall[2]==`NoStop)||(wr_Mem[1]==1'b0))	begin
		id_pc<=`ZeroHalfWord;
		id_inst<=`EXE_NOP_OP; //取指阶段暂停，向译码阶段传递空指令
		end
	else if(stall[1]==`NoStop)	begin
	//		if(wr_Mem[1]==1'b0)	begin
			if(we==`ChipRead)
			begin
			id_pc<=if_pc;             //向id传递if阶段的值
			id_inst<=mem_data_in;
			end
			else if(we==`ChipWrite)   //无影响
			begin
			end
	end
end
endmodule 