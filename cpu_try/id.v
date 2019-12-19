`include"define.v"
module id(
	input wire 							rst,
	input wire[`InstAddrBus] 		pc_i,  		//译码阶段的指令对应的地址
	input wire[`InstBus]				inst_i,		//译码阶段的指令
	//从通用寄存器读取的值
	input wire[`RegBus]				reg1_data_i, //寄存器组 读端口1 的输入数据  dr
	input wire[`RegBus]				reg2_data_i, 	//寄存器        2		sr
//写入通用寄存器的值
	output reg 							reg1_read_o, 	//寄存器组 读端口1 的使能信号
	output reg							reg2_read_o,	//					2
	output reg[`RegAddrBus]			reg1_addr_o,	//寄存器组	 读端口1的地址选择信号
	output reg[`RegAddrBus]			reg2_addr_o,
//送到执行阶段的信息
	output reg[`AluOpBus]			aluop_o,			//译码阶段的指令要进行运算的子类型
	output reg[`AluSelBus]			alusel_o,		//译码阶段的指令要进行运算的类型
	output reg[`RegBus]				reg1_o,			//译码阶段的指令要进行运算的源操作数1
	output reg[`RegBus]				reg2_o,			//                           2
	output reg[`RegAddrBus]			wd_o,				//译码阶段的指令要写入的目的寄存器地址
	output reg 							wreg_o,  		//译码阶段的指令是否有要写入的目的寄存器
	output reg 							flag_upd_o,	//是否更新标志位
//解决数据相关问题
	input wire		ex_wreg_i,
	input wire[`RegAddrBus]	ex_wd_i,
	input wire[`RegBus]		ex_wdata,
//	
	input wire		mem_wreg_i,
	input wire[`RegAddrBus]	mem_wd_i,
	input wire[`RegBus]		mem_wdata,
	output wire					stallreq, //load store
	
	//跳转指令
	input wire     			id_c,
	input wire 					id_z,
	input wire					is_in_delayslot_i,
	output reg					next_inst_in_delayslot_o,
	output reg 					branch_flag_o,
	output reg[`RegBus]		branch_target_address_o,
	output reg[`RegBus]		link_addr_o,
	output reg					is_in_delayslot_o   //如果为1，表示此阶段为延迟槽指令
);

wire[`RegBus]		pc_plus_4;      // 硬件  	2   仿真	4
wire[`RegBus]		pc_plus_2; //修改				1			2
wire[`RegBus]		imm_sll2_signedext;
assign 	pc_plus_4	=	pc_i	+4;		//保存当前译码阶段指令后第2条指令的地址
assign   pc_plus_2	=	pc_i	+2;		//保存当前译码阶段指令后第一条指令的地址

assign stallreq = `NoStop;
//获得指令的指令码
wire[3:0] op_type  = inst_i[15:12];   //操作码前4位
wire[3:0] op		 = inst_i[11:8];
wire[3:0] op1 = inst_i[7:4];
wire[3:0] op2 = inst_i[3:0];
//保存指令中的立即数
reg[`RegBus] imm;           

//指令是否有效
reg instvalid;
reg immenable;
/********************——1——指令译码*********************/

always @(*) begin
	if(rst==`RstEnable) begin
		aluop_o		<=		`EXE_NOP_OP;
		alusel_o		<=		`EXE_RES_NOP;
		wd_o			<=		`NOPRegAddr;
		wreg_o		<=		`WriteDisable;
		instvalid   <= 	`InstValid;
		reg1_read_o	<=		1'b0;
		reg2_read_o	<=		1'b0;
		reg1_addr_o	<=		`NOPRegAddr;
		reg2_addr_o	<=		`NOPRegAddr;
		imm			<=		16'h0;
		flag_upd_o		<=		`NoFlagUpd;
		link_addr_o	<=	`ZeroHalfWord;
		branch_target_address_o<=`ZeroHalfWord;
		branch_flag_o	<=	`NotBranch;
		next_inst_in_delayslot_o	<=`NotInDelaySlot;
		end
	else begin
		aluop_o		<=		`EXE_NOP_OP;
		alusel_o		<=		`EXE_RES_NOP;
		wd_o			<=		inst_i[7:4];    //写入寄存器的序号 
		wreg_o		<=		`InstInvalid;
		flag_upd_o		<=		`NoFlagUpd;
		reg1_read_o <=		1'b0;
		reg2_read_o <=		1'b0;  
		reg1_addr_o	<=		inst_i[7:4];		//DR寄存器
		reg2_addr_o	<=		inst_i[3:0];		//SR寄存器
		imm <= `ZeroHalfWord;
		flag_upd_o		<=		`NoFlagUpd;
		link_addr_o	<=	`ZeroHalfWord;
		branch_target_address_o<=`ZeroHalfWord;
		branch_flag_o	<=	`NotBranch;
		next_inst_in_delayslot_o	<=`NotInDelaySlot;
		case(op_type)
				`INST_1:begin    //基本的加减 + 逻辑运算
						case(op)
							`EXE_ADD:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_ADD_OP;
										alusel_o	<=`EXE_RES_ARITHMETIC;
										reg1_read_o	<=	1'b1;
										reg2_read_o	<=	1'b1;
										wd_o		<=	op1;
										flag_upd_o	<=	1'b1;
										instvalid<=`InstValid;
										immenable<=1'b0;
										end
							`EXE_SUB:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_SUB_OP;
										alusel_o	<=`EXE_RES_ARITHMETIC;
										reg1_read_o<=	1'b1;
										reg2_read_o<=	1'b1;
										wd_o		<=	op1;
										flag_upd_o	<=1'b1;
										instvalid<=	`InstValid;
										immenable<=1'b0;
										end
							`EXE_DEC:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_SUB_OP;
										alusel_o	<=`EXE_RES_ARITHMETIC;
										reg1_read_o	<=	1'b1;
										reg2_read_o	<=	1'b0;
										imm	<=	16'h0001;
										wd_o	<=	op1;
										flag_upd_o	<=1'b1;
										instvalid	<=	`InstValid;
										immenable	<=1'b1;
										end
							`EXE_INC:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_ADD_OP;
										alusel_o	<=`EXE_RES_ARITHMETIC;
										reg1_read_o	<=	1'b1;
										reg2_read_o	<=	1'b0;
										imm	<= 16'h0001;
										wd_o	<=	op1;
										instvalid	<=`InstValid;
										flag_upd_o	<=1'b1;
										immenable	<=1'b1;
										end
							`EXE_CMP:	begin
										wreg_o	<=`WriteDisable;
										aluop_o		<=`EXE_CMP_OP;
										alusel_o	<=`EXE_RES_ARITHMETIC;
										reg1_read_o<=1'b1;
										reg2_read_o	<=1'b1;
										instvalid<=`InstValid;
										flag_upd_o<=1'b1;
										immenable	<=1'b0;
										end
							`EXE_AND:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_AND_OP;
										alusel_o	<=`EXE_RES_LOGIC;
										reg1_read_o	<=	1'b1;
										reg2_read_o	<=	1'b1;
										wd_o		<=	op1;
										instvalid<=`InstValid;
										immenable<=	1'b0;
										end
							`EXE_OR:		begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_OR_OP;		//运算子类型是或运算
										alusel_o	<=`EXE_RES_LOGIC;	//运算类型是逻辑运算4
										reg1_read_o	<=	1'b1;
										reg2_read_o	<=	1'b1;
								//		imm	<=	{16'h0,inst_i[15:0]};
										wd_o	<=	op1;  		//[7:4]为目的寄存器
										instvalid	<=	`InstValid;
										immenable	<=	1'b0;
										end
							`EXE_NOT:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_NOT_OP;
										alusel_o	<=`EXE_RES_LOGIC;
										reg1_read_o	<=1'b1;
										reg2_read_o	<=1'b0;
										imm		<=16'h0;
										wd_o		<=op1;
										instvalid<=`InstValid;
										immenable	<=1'b0;
										end
							`EXE_XOR:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_XOR_OP;
										alusel_o	<=`EXE_RES_LOGIC;
										reg1_read_o	<=	1'b1;
										reg2_read_o	<=	1'b1;
										instvalid<=`InstValid;
										immenable	<=1'b0;
										end
							`EXE_TEST:	begin
										wreg_o	<=`WriteDisable;
										aluop_o	<=`EXE_TEST_OP;
										alusel_o	<=`EXE_RES_LOGIC;
										reg1_read_o	<=	1'b1;
										reg2_read_o	<=	1'b1;
										instvalid<=`InstValid;
										flag_upd_o	<=	1'b1;
										immenable	<=1'b0;
										end
							`EXE_SHL:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_SHL_OP;
										alusel_o	<=`EXE_RES_SHIFT;
										reg1_read_o<=1'b1;
										reg2_read_o<=1'b0;
										flag_upd_o	<=1'b1;
										wd_o		<=op1;
										instvalid<=`InstValid;
										immenable<=1'b0;
										end
							`EXE_SHR:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_SHR_OP;
										alusel_o	<=`EXE_RES_SHIFT;
										reg1_read_o<=1'b1;
										reg2_read_o<=1'b0;
										flag_upd_o	<=1'b1;
										wd_o		<=op1;
										instvalid<=`InstValid;
										immenable<=1'b0;
										end
							`EXE_SAR:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_SAR_OP;
										alusel_o	<=`EXE_RES_SHIFT;
										reg1_read_o	<=1'b1;
										reg2_read_o	<=1'b0;
										wd_o		<=op1;
										instvalid<=`InstValid;
										immenable<=1'b0;
										end
							default:	begin
							end
						endcase
						end
				`INST_2:begin		//立即数
						case(op)
							`EXE_LOADH:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_ADD_OP;
										alusel_o	<=`EXE_RES_ARITHMETIC;
										reg1_read_o	<=	1'b1;
										reg1_addr_o <=	4'b1111;
										reg2_read_o	<=	1'b0;
										imm	<=	{op1,op2,reg1_data_i[7:0]};
										wd_o	<=4'b1111;   //15号寄存器
										instvalid	<=	`InstValid;
										immenable	<=	1'b1;
										end
							`EXE_LOADL:	begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_ADD_OP;
										alusel_o	<=`EXE_RES_ARITHMETIC;
										reg1_read_o	<=	1'b1;
										reg1_addr_o	<=	4'b1111;
										reg2_read_o	<=	1'b0;
										imm	<={reg1_data_i[15:8],op1,op2};
										wd_o	<=4'b1111;
										instvalid	<=`InstValid;
										immenable	<=1'b1;
										end
								default:	begin
										end
						endcase
							end
				`INST_3:begin
						case(op)
							`EXE_LOAD: begin
										wreg_o<=`WriteEnable;
										aluop_o<=`EXE_LOAD_OP;
										alusel_o<=`EXE_RES_LOAD_STORE;
										reg1_read_o<=1'b1;
										reg2_read_o<=1'b1;
										wd_o	<=	op1;
										instvalid<=	`InstValid;
										end
							`EXE_STORE:	begin
										wreg_o<=`WriteDisable;
										aluop_o<=`EXE_STORE_OP;
										alusel_o<=`EXE_RES_LOAD_STORE;
										reg1_read_o<=1'b1;
										reg2_read_o<=1'b1;
										instvalid<=`InstValid;
										end
							default:	begin		end
						endcase
						end
				`INST_4:begin   //NOP指令
						case(op)
									`EXE_NOP:	begin
												wreg_o	<=`WriteDisable;
												aluop_o	<=`EXE_NOP_OP;
												alusel_o	<=`EXE_RES_NOP;
												reg1_read_o<=1'b0;
												reg2_read_o<=1'b0;
												immenable<=1'b0;
												instvalid<=`InstValid;
													end
										default:	begin
													end
								endcase
							end
				`INST_5:begin		//移位指令 HILO
						case(op)
							`EXE_MFHI:begin
								wreg_o	<=`WriteEnable;
								aluop_o	<=`EXE_MFHI_OP;
								alusel_o	<=`EXE_RES_MOVE;
								reg1_read_o<=1'b0;
								reg2_read_o<=1'b0;
								instvalid<=`InstValid;
								immenable<=1'b0;
										end
							`EXE_MFLO:begin
								wreg_o	<=`WriteEnable;
								aluop_o	<=`EXE_MFLO_OP;
								alusel_o	<=`EXE_RES_MOVE;
								reg1_read_o<=1'b0;
								reg2_read_o<=1'b0;
								instvalid<=`InstValid;
								immenable<=1'b0;
										end
							`EXE_MTHI:begin
								wreg_o	<=`WriteDisable;
								aluop_o	<=`EXE_MTHI_OP;
								reg1_read_o<=1'b0;
								reg2_read_o<=1'b1;
								instvalid<=`InstValid;
								immenable<=1'b0;
										end
							`EXE_MTLO:begin  //源寄存器到LO
								wreg_o	<=`WriteDisable;
								aluop_o	<=`EXE_MTLO_OP;
								reg1_read_o<=1'b0;
								reg2_read_o<=1'b1;
								instvalid<=`InstValid;
								immenable<=1'b0;
										end
							`EXE_MOVE:begin
										wreg_o	<=`WriteEnable;
										aluop_o	<=`EXE_MOVE_OP;
										alusel_o	<=`EXE_RES_MOVE;
										reg1_read_o<=1'b0;
										reg2_read_o<=1'b1;
										wd_o		<=op1;
										instvalid<=`InstValid;
										immenable<=1'b0;
										end							
							`EXE_MOVN:begin
								aluop_o	<=`EXE_MOVN_OP;
								alusel_o	<=`EXE_RES_MOVE;
								reg1_read_o<=1'b1;
								reg2_read_o<=1'b1;
								instvalid<=`InstValid;
								if(reg1_o!=`ZeroHalfWord)	begin
										wreg_o<=`WriteEnable;
										end
								else 	begin	
										wreg_o<=`WriteDisable;
										end
										end
							`EXE_MOVZ:begin
								aluop_o	<=`EXE_MOVN_OP;
								alusel_o	<=`EXE_RES_MOVE;
								reg1_read_o<=1'b1;
								reg2_read_o<=1'b1;
								instvalid<=`InstValid;
								if(reg1_o==`ZeroHalfWord)	begin //reg1为目的寄存器
										wreg_o<=`WriteEnable;
										end
								else 	begin	
										wreg_o<=`WriteDisable;
										end
										end
							default:	begin			end
						endcase
						end
				`INST_6:begin  //乘除
						case(op)
								`EXE_MUL:	begin
									wreg_o<=`WriteDisable;
									aluop_o<=`EXE_MUL_OP;
									alusel_o<=`EXE_RES_MUL;
									reg1_read_o<=1'b1;
									reg2_read_o<=1'b1;
									instvalid<=`InstValid;
									flag_upd_o<=1'b1;
									immenable<=1'b0;
									end
								`EXE_MULU:	begin
									wreg_o<=`WriteDisable;
									aluop_o<=`EXE_MULU_OP;
									alusel_o<=`EXE_RES_MUL;
									reg1_read_o<=1'b1;
									reg2_read_o<=1'b1;
									instvalid<=`InstValid;
									immenable<=1'b0;
									end
								`EXE_DIV:	begin  //aluopsel_o 默认EXE_RES_NOP;
									wreg_o<=`WriteDisable; 
									aluop_o<=`EXE_DIV_OP;
									reg1_read_o<=1'b1;
									reg2_read_o<=1'b1;
									instvalid<=`InstValid;
									immenable<=1'b0;
									end
								`EXE_DIV:	begin
									wreg_o<=`WriteDisable;
									aluop_o<=`EXE_DIVU_OP;
									reg1_read_o<=1'b1;
									reg2_read_o<=1'b1;
									instvalid<=`InstValid;
									immenable<=1'b0;
									end
								default:	begin	end
							endcase
						end
				`INST_7:begin
							case(op)
								`EXE_J:		begin
									wreg_o<=`WriteDisable;
									aluop_o<=`EXE_J_OP;
									alusel_o<=`EXE_RES_JUMP_BRANCH;
									reg1_read_o	<=1'b0;
									reg2_read_o	<=1'b0;
									immenable	<=1'b0;
									link_addr_o	<=`ZeroHalfWord;
									branch_flag_o	<=`Branch;
									next_inst_in_delayslot_o<=`InDelaySlot;
									instvalid	<=	`InstValid;
									branch_target_address_o	<= pc_i	+{8'h00,inst_i[7:0]};
									end
								`EXE_JC:		begin
									if(id_c==1'b1)	begin
										wreg_o<=`WriteDisable;
										aluop_o<=`EXE_J_OP;
										alusel_o<=`EXE_RES_JUMP_BRANCH;
										reg1_read_o	<=1'b0;
										reg2_read_o	<=1'b0;
										imm	<={op1,op2};
										link_addr_o	<=`ZeroHalfWord;
										branch_flag_o	<=`Branch;
										next_inst_in_delayslot_o<=`InDelaySlot;
										instvalid	<=	`InstValid;
										branch_target_address_o	<= pc_i	+{8'h00,pc_i[7:0]};
												end
									else begin		end
									end
								`EXE_JNC:	begin
									if(id_c==1'b0)	begin
										wreg_o<=`WriteDisable;
										aluop_o<=`EXE_J_OP;
										alusel_o<=`EXE_RES_JUMP_BRANCH;
										reg1_read_o	<=1'b0;
										reg2_read_o	<=1'b0;
										immenable	<=1'b0;
										imm	<={op1,op2};
										link_addr_o	<=`ZeroHalfWord;
										branch_flag_o	<=`Branch;
										next_inst_in_delayslot_o<=`InDelaySlot;
										instvalid	<=	`InstValid;
										branch_target_address_o	<= pc_i	+{8'h00,inst_i[7:0]};
												end
									else begin		end
									end
								`EXE_JZ:		begin
									if(id_z==1'b1)	begin
										wreg_o<=`WriteDisable;
										aluop_o<=`EXE_J_OP;
										alusel_o<=`EXE_RES_JUMP_BRANCH;
										reg1_read_o	<=1'b0;
										reg2_read_o	<=1'b0;
										immenable	<=1'b0;
										imm	<={op1,op2};
										link_addr_o	<=`ZeroHalfWord;
										branch_flag_o	<=`Branch;
										next_inst_in_delayslot_o<=`InDelaySlot;
										instvalid	<=	`InstValid;
										branch_target_address_o	<= pc_i	+{8'h00,inst_i[7:0]};
												end
									else begin		end
									end
								`EXE_JNZ:	begin
									if(id_z==1'b0)	begin
										wreg_o<=`WriteDisable;
										aluop_o<=`EXE_J_OP;
										alusel_o<=`EXE_RES_JUMP_BRANCH;
										reg1_read_o	<=1'b0;
										reg2_read_o	<=1'b0;
										immenable	<=1'b0;
										imm	<={op1,op2};
										link_addr_o	<=`ZeroHalfWord;
										branch_flag_o	<=`Branch;
										next_inst_in_delayslot_o<=`InDelaySlot;
										instvalid	<=	`InstValid;
										branch_target_address_o	<= pc_i	+{8'h00,inst_i[7:0]};
												end
									else begin		end
									end
						default:	begin	end
						endcase
						end
									
			default:	begin
						end
			
		endcase
	end
end
//延迟槽
always@(*)	begin
	if(rst==`RstEnable)	begin
	is_in_delayslot_o<=`NotInDelaySlot;  //_i当前译码指令是否是延迟槽指令
			end
	else begin
	is_in_delayslot_o	<= is_in_delayslot_i;
	end
end
/*                    确定源操作数1           */
always @(*) begin
	if(rst==`RstEnable) begin
		reg1_o<=`ZeroHalfWord;
		end
	else if((reg1_read_o==1'b1)&&(ex_wreg_i==1'b1)&&(reg1_addr_o==ex_wd_i))		begin  //译码阶段要读的寄存器是执行阶段要写的寄存器则
				reg1_o<=ex_wdata;	end
	else if((reg1_read_o==1'b1)&&(mem_wreg_i==1'b1)&&(reg1_addr_o==mem_wd_i))	begin	//译码阶段要读的寄存器是访存阶段要写的寄存器
				reg1_o<=mem_wdata;	end					
	else if((reg1_read_o == 1'b1)&&((op!=`EXE_LOADH)||(op!=`EXE_LOADL)))	begin
			reg1_o<=reg1_data_i; //寄存器组 读端口1 的输出值
			end
//	else if((reg1_read_o == 1'b0)&&(immenable ==1'b1)) 	begin
	//		reg1_o<=imm;         //立即数  如果立即数不参与运算，则在译码阶段将立即数置零
		//	end
	else	begin
			reg1_o<=`ZeroHalfWord;
			end
end



/*                 确定源操作数2             */
always @(*) begin
	if(rst==`RstEnable) begin
		reg2_o<=`ZeroHalfWord;
		end
	else if((reg2_read_o==1'b1)&&(ex_wreg_i==1'b1)&&(reg2_addr_o==ex_wd_i))		begin  //译码阶段要读的寄存器是执行阶段要写的寄存器则
				reg2_o<=ex_wdata;	end
	else if((reg2_read_o==1'b1)&&(mem_wreg_i==1'b1)&&(reg2_addr_o==mem_wd_i))	begin	//译码阶段要读的寄存器是访存阶段要写的寄存器
				reg2_o<=mem_wdata;	end	
	else if(reg2_read_o == 1'b1)	begin
		reg2_o<=reg2_data_i;    //寄存器组  读端口2 的输出值
		end
	else if((reg2_read_o ==1'b0)&&(immenable==1'b1))	begin
		reg2_o<=imm;
		end
	else begin
		reg2_o<=`ZeroHalfWord;
		end
	end

endmodule 