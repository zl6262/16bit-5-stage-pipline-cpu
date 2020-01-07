`include"define.v"
module pc_reg(
	input wire clk,
	input wire rst,
	input wire[5:0] stall,  //流水线暂停
	//应添加 控制we的信号 chip   //根据指令的类型
	input wire branch_flag_i,
	input wire [`RegBus]	branch_target_address_i,
	//增加 要写内存的数据的地址信号
	output reg[`InstAddrBus] pc,
	
	//
	//input wire[`RegBus]		mem_addr_i,
	input wire[1:0]			wr_Mem,//信号
	
	//
	output wire	we
	);
	
	
	assign we = (wr_Mem==2'b01)?	`ChipWrite: `ChipRead;
	always@(posedge clk)
	begin
	if( rst == `RstEnable)
		begin
	//	we<=`ChipRead; //复位的时候指令存储器禁用
		pc<=16'h0000;
		end
	else begin
	//			we<=`ChipRead;
		if(wr_Mem==2'b00)	begin
	//			we<=`ChipRead;
				pc<=pc;
				end
		else if(wr_Mem==2'b01)	begin
	//			we<=`ChipWrite;
				pc<=pc;
				end
		else	if(stall[0]==`NoStop)
			begin
				if(we==`ChipRead)	begin
					if(branch_flag_i==`Branch)	begin
					pc<=branch_target_address_i;end
					else	begin
						pc<=pc+4'h2;
						end
					end
				else if(we==`ChipWrite) begin
						pc<=16'h0000;       //无需修改  ----alu_out 写地址
						end
			end
		end                  // 待修改


end
endmodule 