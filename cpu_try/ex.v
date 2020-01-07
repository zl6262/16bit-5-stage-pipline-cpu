`include"define.v"
module ex(
	input	wire rst,
// 译码阶段传输到执行阶段的信息
	input wire[`AluOpBus]	aluop_i,
	input wire[`AluSelBus]	alusel_i,
	input wire[`RegBus]		reg1_i,
	input wire[`RegBus]		reg2_i,
	input wire[`RegAddrBus]	wd_i,
	input wire					wreg_i,
//	输入的标志位
	input wire 					c_i,
	input wire 					v_i,
	input wire 					z_i,
	input wire 					s_i,
	input wire 					ex_flag_upd_i,
//	输出的标志位
	output reg 					c_o,
	output reg					v_o,
	output reg					z_o,
	output reg					s_o,
//执行的结果
	output reg[`RegAddrBus]	wd_o,
	output reg					wreg_o,
	output reg[`RegBus]		wdata_o,
//HILO的输入值
	input wire[`RegBus]		hi_i,
	input wire[`RegBus]		lo_i,
//回写阶段指令是否要写HI,LO,用来检测hI,lo带来的数据相关问题
	input wire[`RegBus]		wb_hi_i,
	input wire[`RegBus]		wb_lo_i,
	input wire					wb_whilo_i,
//访存阶段的指令是否要写入HI,LO，用于检测数据相关
	input wire[`RegBus]		mem_hi_i,
	input wire[`RegBus]		mem_lo_i,
	input wire					mem_whilo_i,
//执行阶段的指令对HI，lo的写操作请求
	output reg 			whilo_o,
	output reg[`RegBus]		hi_o,
	output reg[`RegBus]		lo_o,
//除法指令
	input wire[`DoubleRegBus]	div_result_i,
	input wire 						div_ready_i,
	output reg[`RegBus]			div_opdata1_o,
	output reg[`RegBus]			div_opdata2_o,
	output reg						div_start_o,
	output reg 						signed_div_o,
	output reg				stallreq ,
	
	input wire[`RegBus]			link_address_i,		//处于执行阶段的指令要保存的返回地址
	input wire						is_in_delayslot_i,//当前执行的指令是否位于延迟槽 异常处理时需要
//	output reg[1:0]				wr_Mem,
	output reg[`AluOpBus]		aluop_o,
	output reg[`RegBus]			mem_addr_o,
	output reg[`RegBus]			data_store
);
always @(*)
	begin
 aluop_o	=aluop_i;
end
//always@(*)	begin
//		if(rst==`RstEnable)	begin						wr_Mem <= 2'b1x;	end
//		else begin
//			wr_Mem	<= 2'b10;
//			if(aluop_i == `EXE_LOAD_OP)	begin			wr_Mem <= 2'b00;	end
//			else if(aluop_i ==`EXE_STORE_OP)	begin		wr_Mem <= 2'b01;	end
//		end
//	end

//assign aluop_o	=aluop_i;
//assign mem_addr_o	= (aluop_i==`EXE_LOAD_OP)?	reg2_i:
//							(aluop_i==`EXE_STORE_OP)? reg1_i:16'hzzzz;
//assign data_store = (aluop_i==`EXE_STORE_OP)? reg2_i:16'hzzzz;
always@(*)	begin
if(rst ==`RstEnable)	begin
		mem_addr_o	<= 16'h0000;
		end
else begin
		mem_addr_o	<= 16'h0000;
		if(aluop_i==`EXE_LOAD_OP)	begin
					mem_addr_o	<= reg2_i;
					end
		else if(aluop_i==`EXE_STORE_OP)	begin
					mem_addr_o <= reg1_i;
					data_store <= reg2_i;
					end
		end
end
reg stallreq_for_div;  //判断是否由于除法运算导致流水线暂停

wire z_temp;
reg c_temp_1;
wire c_temp;
wire s_temp;	
wire ov_sum;	//保存溢出情况
wire reg1_eq_reg2;
wire reg1_lt_reg2;
reg[`RegBus]	arithmeticres;//保存算术运算的结果
wire[`RegBus]	reg2_i_mux;//保存第二个操作数的补码
wire[`RegBus]	reg1_i_not;	//保存第一个操作数的反码
wire[`RegBus]	result_sum;//保存加法结果
wire[`RegBus]	opdata1_mult;	//保存乘法中的被乘数
wire[`RegBus]	opdata2_mult;	//乘法操作中的乘数
	
	
//保存逻辑运算的结果
reg[`RegBus] logicout;
//保存移位运算结果
reg[`RegBus] shiftres;
reg[`RegBus]	moveres;
reg[`RegBus]	HI;
reg[`RegBus]	LO;	//保存LO寄存器的最新值

wire[`DoubleRegBus]	hilo_temp; //临时保存乘法结果	
reg[`DoubleRegBus]	mulres; //保存乘法结果


//如果是减法或有符号运算 reg2_i_mux等于第二个操作数的补码
assign reg2_i_mux = ((aluop_i ==`EXE_SUB_OP) || 
							(aluop_i==`EXE_CMP_OP)) ?
							(~reg2_i+1):reg2_i;
assign result_sum = reg1_i + reg2_i_mux;

assign z_temp	= (((aluop_i==`EXE_TEST_OP)&&(logicout==16'b0))||
						((aluop_i==`EXE_SUB_OP||aluop_i==`EXE_ADD_OP||aluop_i==`EXE_CMP_OP)&&(result_sum==16'b0))
						)?1'b1:1'b0;
//计算是否溢出
assign ov_sum	=((!reg1_i[15] && !reg2_i[15]) &&	result_sum[15])
			|| ((reg1_i[15] &&reg2_i[15] &&(!result_sum[15])));
assign c_temp	=(aluop_i==`EXE_ADD_OP)?ov_sum:~ov_sum;  //加减法的c，v相同。
assign s_temp = (aluop_i ==`EXE_MUL_OP)	?	mulres[31]: result_sum[15];	//符号运算
   //符号位与最高位相同  //add sub 	dec inc cmp 
always@(*)		
	begin
	if(rst==`RstEnable) begin
				c_o<=1'b0;
				v_o<=1'b0;
				z_o<=1'b0;
				s_o<=1'b0;
				end
	else if(ex_flag_upd_i==1'b1)	begin
				c_o<=c_i;
				v_o<=v_i;
				z_o<=z_i;
				s_o<=s_i;
			case(aluop_i)
				`EXE_ADD_OP:	begin
									c_o<=c_temp; 
									v_o<=ov_sum;
									end
				`EXE_SUB_OP:	begin
									c_o<=ov_sum;
									v_o<=ov_sum;
									z_o<=z_temp;
									end
				`EXE_TEST_OP,`EXE_CMP_OP:
									begin 	z_o<=z_temp;	end
				`EXE_SHL_OP,`EXE_SHR_OP,`EXE_SAR_OP:begin
									c_o<=c_temp_1;
									end
				`EXE_MUL:		begin
									s_o<=s_temp;
									end
				default:		begin			end
				endcase
			end
//			if((aluop_i==`EXE_SHL_OP)||(aluop_i==`EXE_SHR_OP))begin
//				c_o<=c_temp_1;
//				end
//			else begin c_o<=c_temp;end
//			if((aluop_i==`EXE_ADD_OP)||(aluop_i==`EXE_SUB_OP))begin
//				v_o<=ov_sum;
//			end
//				z_o<=z_temp;
//				if((aluop_i==`EXE_ADD_OP)||(aluop_i==`EXE_SUB_OP)||(aluop_i==`EXE_MUL_OP))
//				s_o<=s_temp;
//				end
	end
//计算操作数是否小于操作二
//as
 
//解决HI LO的数据相关
always@(*)	begin
	if(rst==`RstEnable)	begin
		{HI,LO}<={`ZeroHalfWord,`ZeroHalfWord};
	end else if(mem_whilo_i==`WriteEnable)	begin
		{HI,LO}<={mem_hi_i,mem_lo_i};// 访存阶段的指令前推
	end else if(wb_whilo_i ==`WriteEnable)	begin
		{HI,LO}<={wb_hi_i,wb_lo_i};	//回写阶段的指令前推
	end else begin
		{HI,LO}<={hi_i,lo_i};
	end
end

/*   根据aluop_i指示的运算子类型进行运算，  逻辑或 运算         */
always @(*)	begin
	if(rst == `RstEnable)	begin logicout<=`ZeroHalfWord; 	end
	else	begin
		case(aluop_i)
			`EXE_OR_OP:	begin	logicout <= reg1_i | reg2_i;	end
			`EXE_AND_OP:begin	logicout	<=	reg1_i & reg2_i;	end
			`EXE_NOT_OP:begin logicout	<=	~reg1_i;				end
			`EXE_XOR_OP:begin	logicout	<=	reg1_i ^	reg2_i;	end
			`EXE_TEST_OP:begin 	logicout<=	reg1_i & reg2_i;			end
				default:	begin logicout <= `ZeroHalfWord;		end
				
		endcase
	end	
end

//算术运算

always@(*)	begin
	if(rst==`RstEnable)	begin
		arithmeticres <=	`ZeroHalfWord;	end
	 else begin
		case(aluop_i)
			`EXE_ADD_OP:	begin	arithmeticres<=result_sum;	end
			`EXE_SUB_OP:	begin	arithmeticres<=result_sum;	end
			default:	begin		arithmeticres<=`ZeroHalfWord;	end
			endcase
		end
	
end
//乘法运算
assign opdata1_mult =((aluop_i==`EXE_MUL_OP)&&(reg1_i[15]==1'b1))?(~reg1_i+1):reg1_i;
assign opdata2_mult =((aluop_i==`EXE_MUL_OP)&&(reg2_i[15]==1'b1))?(~reg2_i+1):reg2_i;
assign hilo_temp	=	opdata1_mult*opdata2_mult;	//保存临时乘法的结果
//乘法的临时结果需要修正，
//1.有符号乘法， 如果被乘数与乘数一正一负，需对结果求补码
//2.有符号  两乘数同正负，则无需修正，无符号无需修正
always@(*)	begin
	if(rst==`RstEnable)	begin
			mulres<={`ZeroHalfWord,`ZeroHalfWord};
	end else if(aluop_i==`EXE_MUL_OP)
					begin
						if(reg1_i[15]^reg2_i[15]==1'b1)	begin
						mulres<= ~hilo_temp + 1;
						end	else begin
						mulres<= hilo_temp;
						end
					end	else begin
						mulres<= hilo_temp;
						end
	end
//除法运算  输出除法器控制信息，获取触发器的结果信号
always@(*)	begin
if(rst==`RstEnable)	begin
	stallreq_for_div	<=	`NoStop;
	div_opdata1_o		<=	`ZeroHalfWord;
	div_opdata2_o		<=	`ZeroHalfWord;
	div_start_o			<=	`DivStop;
	signed_div_o		<=	1'b0;
	end
else begin
	stallreq_for_div	<=	`NoStop;
	div_opdata1_o		<=	`ZeroHalfWord;
	div_opdata2_o		<=	`ZeroHalfWord;
	div_start_o			<=	`DivStop;
	signed_div_o		<=	1'b0;
	case(aluop_i)
		`EXE_DIV_OP:	begin
			if(div_ready_i	==	`DivResultNotReady)	begin
				div_opdata1_o	<=	reg1_i;
				div_opdata2_o	<=	reg2_i;
				div_start_o		<=	`DivStart;
				signed_div_o	<=	1'b1;
				stallreq_for_div<=`Stop;
					end
			else if(div_ready_i == `DivResultReady) begin
				div_opdata1_o	<=	reg1_i;
				div_opdata2_o	<=	reg2_i;
				div_start_o		<=	`DivStop;
				signed_div_o	<=	1'b1;
				stallreq_for_div<=`NoStop;
				end
			else begin
				div_opdata1_o	<=	`ZeroHalfWord;
				div_opdata2_o	<=	`ZeroHalfWord;
				signed_div_o	<=	1'b0;
				div_start_o		<=	`DivStop;
				stallreq_for_div<=`NoStop;
				end
			end
		`EXE_DIVU_OP:	begin
			if(div_ready_i ==`DivResultNotReady)	begin
				div_opdata1_o	<=	reg1_i;
				div_opdata2_o	<=	reg2_i;
				div_start_o		<=	`DivStart;
				signed_div_o	<=	1'b0;
				stallreq_for_div<=`Stop;
					end
			else if(div_ready_i == `DivResultReady) begin
				div_opdata1_o	<=	reg1_i;
				div_opdata2_o	<=	reg2_i;
				div_start_o		<=	`DivStop;
				signed_div_o	<=	1'b0;
				stallreq_for_div<=`NoStop;
				end
			else begin
				div_opdata1_o	<=	`ZeroHalfWord;
				div_opdata2_o	<=	`ZeroHalfWord;
				signed_div_o	<=	1'b0;
				div_start_o		<=	`DivStop;
				stallreq_for_div<=`NoStop;
				end
			end
		default:	begin	end
		endcase
	end
end
always@(*)		begin
	stallreq = stallreq_for_div || (1'b0);
	end

// 移位运算
always@(*)begin
	if(rst==`RstEnable)	begin	shiftres	<=`ZeroHalfWord;	end
	else	begin
			case(aluop_i)
			`EXE_SHL_OP:	begin	shiftres	<=	{reg1_i[14:0],1'b0};
								// 待添加状态更新c
										c_temp_1<=	reg1_i[15];
								end
			`EXE_SHR_OP:	begin shiftres	<=	{1'b0,reg1_i[15:1]};
										c_temp_1<= reg1_i[0];
								end
			`EXE_SAR:		begin	shiftres	<=	{reg1_i[0],reg1_i[15:1]};	end
			default:	begin	shiftres	<=	`ZeroHalfWord;end
			endcase
			end
end
// 移动运算
always@(*)begin
	if(rst==`RstEnable)	begin	moveres<=`ZeroHalfWord;	end
	else	begin
	moveres<=`ZeroHalfWord;
	case(aluop_i)
		`EXE_MFHI_OP:		begin	moveres<=HI;	end
		`EXE_MFLO_OP:		begin	moveres<=LO;	end
		`EXE_MOVE_OP:		begin	moveres<=reg2_i;end
		`EXE_MOVZ_OP:		begin	moveres<=reg2_i;end
		`EXE_MOVN_OP:		begin	moveres<=reg2_i;end
		default:	begin 	end
		endcase
	end
end
//根据alusel_i指示的运算类型，选择一个运算结果作为最终结果    */
always@(*)	begin
	wd_o	<=	wd_i;           //要写入的寄存器地址
	wreg_o	<=	wreg_i;		//是否要写入寄存器
	case(alusel_i)
		`EXE_RES_LOGIC:	begin wdata_o<=logicout;		end 
		`EXE_RES_SHIFT:	begin	wdata_o<=shiftres;		end
		`EXE_RES_MOVE:		begin wdata_o<=moveres;			end
		`EXE_RES_ARITHMETIC:	begin	wdata_o<=arithmeticres;	end
		`EXE_RES_MUL:		begin	wdata_o	<=mulres[15:0];	end
		`EXE_RES_JUMP_BRANCH:	begin	//wdata_o	<=link_address_i;
										end
				 default:	begin	wdata_o<=`ZeroHalfWord;	end
	endcase
end
//向HI，Lo寄存器写值时，对控制信号的赋值
always@(*)	begin
	if(rst==`RstEnable)	begin
		whilo_o<=`WriteDisable;
		hi_o<=`ZeroHalfWord;
		lo_o<=`ZeroHalfWord;
			end
	else	if(aluop_i==`EXE_MTHI_OP)	begin
		whilo_o<=`WriteEnable;
		hi_o<=reg2_i;
		lo_o<=LO;
	end else if(aluop_i==`EXE_MTLO_OP)	begin
		whilo_o<=`WriteEnable;
		hi_o<=HI;
		lo_o<=reg2_i;
	end else if((aluop_i==`EXE_MUL_OP)||
					(aluop_i==`EXE_MULU_OP))begin
		whilo_o<=`WriteEnable;
		hi_o<=mulres[31:16];
		lo_o<=mulres[15:0];
	end else if((aluop_i==`EXE_DIV_OP)||
					(aluop_i==`EXE_DIVU_OP))begin
		whilo_o<=`WriteEnable;
		hi_o<=div_result_i[31:16];		//余数
		lo_o<=div_result_i[15:0];		 //商
	end else begin
		whilo_o<=`WriteDisable;
		hi_o<=`ZeroHalfWord;
		lo_o<=`ZeroHalfWord;
		end
	end

endmodule 