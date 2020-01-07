`include"define.v"
module cpu_try(
	input wire		clk,
	input wire		rst,
	inout wire[`RegBus]	ram_data_i,
	input wire[1:0]	sel,	//选择 控制led的输出 	sel 00  reg_sel输出寄存器值
														//	sel 01  0000 
														/*			  0001 alu第一个输入
																	  0010 alu第二个输入
																	  0011 alu运算结果
																	  0100 HI
																	  0101 LO
																	  其他	 全输出0
															sel 11  1110 PC
																	  1111 IR
																	  */
	input	wire[3:0]	reg_sel,//reg_sel	选择寄存器
	output	wire	c,
	output	wire	z,
	output	wire	v,
	output	wire	s,
//	output	wire	wr;//内存读写功能
	output	wire[`RegBus]	reg_data,

//	output	wire	
	output wire[`RegBus]	ram_addr_o,
	output wire	ram_we_o			//指令存储器使能信号 1为读  
										//                 0为写
										
										
);


//连接 IF/ID  -----ID模块
wire[`InstAddrBus]	pc;
wire[`InstAddrBus]	id_pc_i;
wire[`InstBus]			id_inst_i;

//连接  ID-------ID/EX模块
wire[`AluOpBus]		id_aluop_o;
wire[`AluSelBus]		id_alusel_o;
wire[`RegBus]			id_reg1_o;
wire[`RegBus]			id_reg2_o;
wire						id_wreg_o;
wire[`RegAddrBus]		id_wd_o;
wire						id_flag_upd_o;
wire						id_is_in_delayslot_o;
wire[`RegBus]			id_link_address_o;
//连接	ID/EX-----EX模块
wire[`AluOpBus]		ex_aluop_i;
wire[`AluSelBus]		ex_alusel_i;
wire[`RegBus]			ex_reg1_i;
wire[`RegBus]			ex_reg2_i;
wire						ex_wreg_i;
wire[`RegAddrBus]		ex_wd_i;
wire						ex_flag_upd_i;
wire						ex_is_in_delayslot_i;
wire[`RegBus]			ex_link_address_i;

//连接  EX-----EX/MEM
wire						ex_wreg_o;
wire[`RegAddrBus]		ex_wd_o;
wire[`RegBus]			ex_wdata_o;
wire[`RegBus]			ex_hi_o;
wire[`RegBus]			ex_lo_o;
wire						ex_whilo_o;

//连接   EX/MEM------MEM
wire						mem_wreg_i;
wire[`RegAddrBus]		mem_wd_i;
wire[`RegBus]			mem_wdata_i;
wire[`RegBus]			mem_hi_i;
wire[`RegBus]			mem_lo_i;
wire						mem_whilo_i;
//连接   MEM-------MEM/WB
wire						mem_wreg_o;
wire[`RegAddrBus]		mem_wd_o;
wire[`RegBus]			mem_wdata_o;
wire[`RegBus]			mem_hi_o;
wire[`RegBus]			mem_lo_o;
wire						mem_whilo_o;
//连接		MEM/WB-----WB
wire						wb_wreg_i;
wire[`RegAddrBus]		wb_wd_i;
wire[`RegBus]			wb_wdata_i;
wire[`RegBus]			wb_hi_i;
wire[`RegBus]			wb_lo_i;
wire						wb_whilo_i;
//连接		ID阶段与通用寄存器组的 变量
wire						reg1_read;
wire						reg2_read;
wire[`RegBus]			reg1_data;
wire[`RegBus]			reg2_data;
wire[`RegAddrBus]		reg1_addr;
wire[`RegAddrBus]		reg2_addr;
//连接执行阶段与hilo模块的输出，读取HI，LO寄存器
wire[`RegBus]	hi;
wire[`RegBus]	lo;
//flag 变量
wire 	flag_ci;wire flag_vi;wire flag_zi;wire flag_si;wire flag_co;wire flag_vo;wire flag_zo;wire flag_so;
assign c=flag_co;
assign z=flag_zo;
assign v=flag_vo;
assign s=flag_so;
wire [5:0] stall;
wire       stallreq_from_id;
wire       stallreq_from_ex;

wire is_in_delayslot_i;
wire is_in_delayslot_o;
wire next_inst_in_delayslot_o;
wire id_branch_flag_o;
wire[`RegBus]	branch_target_address;



//除法
wire[15:0]	div_opdata1;
wire[15:0]	div_opdata2;
wire 			div_start;
wire			div_annul;
wire[31:0]	div_result;
wire			div_ready;
wire			signed_div;


wire[`RegBus]		mem_if_addr;
wire[`RegBus]		if_mem_data_load;
wire[`RegBus]		mem_if_data_store;
wire [1:0]			wr_Mem;
wire[`RegBus]		ex_data_store_o;
wire[`RegBus]		ex_mem_addr_o;
wire[`RegBus]		mem_mem_addr_i;
wire[`RegBus]		mem_data_store_i;
wire[`AluOpBus]	ex_aluop_o;
wire[`AluOpBus]	mem_aluop_i;
wire[`RegBus]		regfile_data;

assign reg_data = (sel ==2'b00)? regfile_data:
						(sel ==2'b01)? ((reg_sel==4'b0001)?ex_reg1_i:
											 (reg_sel==4'b0010)?ex_reg2_i:
											 (reg_sel==4'b0011)?ex_wdata_o:
											 (reg_sel==4'b0100)?hi:
											 (reg_sel==4'b0101)?lo:16'h0000):
						(sel ==2'b11)?	 ((reg_sel==4'b1110)?pc:
											  (reg_sel==4'b1111)?ram_addr_o:16'h0000):
											16'h0000;

//pc_reg实例化
pc_reg	pc_reg0(
	.clk(clk),	.rst(rst),	.pc(pc),	.we(ram_we_o), .stall(stall),
	.branch_flag_i(id_branch_flag_o), .branch_target_address_i(branch_target_address),
	.wr_Mem(wr_Mem)
);

//assign	ram_addr_o	=	pc;	//指令存储器的输入地址为pc的值

//  if/id
if_id		if_id0(
		.clk(clk),	.rst(rst),	.if_pc(pc),
		.if_inst(ram_data_i),	.id_pc(id_pc_i),
		.id_inst(id_inst_i),		.we(ram_we_o),
		.stall(stall),          .ram_addr_o(ram_addr_o),
		///
		.mem_addr_i(mem_if_addr), 		.mem_data_i(mem_if_data_store),
		.mem_data_o(if_mem_data_load)	,				.wr_Mem(wr_Mem)
);

id		id0(
		.rst(rst),	.pc_i(id_pc_i),	.inst_i(id_inst_i),
		//从寄存器中读取的数据
		.reg1_data_i(reg1_data),	.reg2_data_i(reg2_data),
		//送到寄存器的控制信号
		.reg1_read_o(reg1_read),	.reg2_read_o(reg2_read),
		.reg1_addr_o(reg1_addr),	.reg2_addr_o(reg2_addr),
		//送到id/ex模块信息
		.is_in_delayslot_i(is_in_delayslot_i),
		.next_inst_in_delayslot_o(next_inst_in_delayslot_o),
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),
		.link_addr_o(id_link_address_o),
		.is_in_delayslot_o(id_is_in_delayslot_o),
		//
		.id_c(flag_co),	.id_z(flag_zo),
		//
		.aluop_o(id_aluop_o),		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),			.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),				.wreg_o(id_wreg_o),
		.ex_wreg_i(ex_wreg_o),		.ex_wd_i(ex_wd_o),
		.ex_wdata(ex_wdata_o),		.mem_wreg_i(mem_wreg_o),
		.mem_wd_i(mem_wd_o),			.mem_wdata(mem_wdata_o),
		.flag_upd_o(id_flag_upd_o),	.stallreq(stallreq_from_id)
);

regfile	regfile1(
		.clk(clk),				.rst(rst),
		.we(wb_wreg_i),		.waddr(wb_wd_i),
		.wdata(wb_wdata_i),	.re1(reg1_read),
		.raddr1(reg1_addr),	.rdata1(reg1_data),
		.re2(reg2_read),		.raddr2(reg2_addr),
		.rdata2(reg2_data),	//.sel(sel),
		.reg_sel(reg_sel),	.regfile_data(regfile_data)
);
		
id_ex	id_ex0(
		.clk(clk),				.rst(rst),
		//id级信息
		.id_aluop(id_aluop_o),	.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),			.id_wreg(id_wreg_o),
		.id_flag_upd(id_flag_upd_o),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),
		//ex
		.ex_aluop(ex_aluop_i),	.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),			.ex_wreg(ex_wreg_i),
		.ex_flag_upd(ex_flag_upd_i), .stall(stall),
		.ex_link_address(ex_link_address_i),
		.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i)
);

ex		ex0(
		.rst(rst),	
		.aluop_i(ex_aluop_i),		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),			.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),				.wreg_i(ex_wreg_i),
		.hi_i(hi),						.lo_i(lo),
		.wb_hi_i(wb_hi_i),			.wb_lo_i(wb_lo_i),
		.c_i(flag_co),					.v_i(flag_vo),
		.z_i(flag_zo),					.s_i(flag_so),
		.ex_flag_upd_i(ex_flag_upd_i),
		.wb_whilo_i(wb_whilo_i),	.mem_hi_i(mem_hi_o),
		.mem_lo_i(mem_lo_o),			.mem_whilo_i(mem_whilo_o),
		//输出信号
		.wd_o(ex_wd_o),				.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),		.hi_o(ex_hi_o),
		.c_o(flag_ci),					.v_o(flag_vi),
		.z_o(flag_zi),					.s_o(flag_si),
		.lo_o(ex_lo_o),				.whilo_o(ex_whilo_o),
		.stallreq(stallreq_from_ex),
		.signed_div_o(signed_div),	.div_opdata1_o(div_opdata1),
		.div_opdata2_o(div_opdata2),
		.div_start_o(div_start),	.div_result_i(div_result),
		.div_ready_i(div_ready),
		.link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),
		///
		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),					.data_store(ex_data_store_o)
	//	.wr_Mem(wr_Mem)
		);

ex_mem 	ex_mem0(
		.clk(clk),		.rst(rst),
		.ex_wd(ex_wd_o),		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),	.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),			.ex_whilo(ex_whilo_o),
		.ex_aluop(ex_aluop_o),				.ex_mem_addr(ex_mem_addr_o),
		.ex_data_store(ex_data_store_o),
		
		.mem_aluop(mem_aluop_i),			.mem_mem_addr(mem_mem_addr_i),
		.mem_data_store(mem_data_store_i),
		.mem_wd(mem_wd_i),	.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i), .mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),		.mem_whilo(mem_whilo_i),
		.stall(stall)
);

mem	mem0(
		.rst(rst),
		.wd_i(mem_wd_i),	.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),	.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),		.whilo_i(mem_whilo_i),
		.wd_o(mem_wd_o),	.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),	.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),		.whilo_o(mem_whilo_o),
		//
		.aluop_i(mem_aluop_i),					.wr_Mem(wr_Mem),
		.mem_addr_i(mem_mem_addr_i),			.mem_data_store(mem_data_store_i),
		.mem_data_i(if_mem_data_load),			.mem_data_o(mem_if_data_store),
		.mem_addr_o(mem_if_addr)
);

mem_wb		mem_wb0(
		.clk(clk),			.rst(rst),
		.mem_wd(mem_wd_o),	.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),	.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),		.mem_whilo(mem_whilo_o),
		//送到回写阶段的信息  ----连接到regfile
		.wb_wd(wb_wd_i),		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),	.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),			.wb_whilo(wb_whilo_i),
		.stall(stall)
		);
hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
		.hi_o(hi),
		.lo_o(lo)
);
ctrl  ctrl0(
		.rst(rst),	.stallreq_from_id(stallreq_from_id),
		.stallreq_from_ex(stallreq_from_ex),
		.stall(stall)
);
flag_reg 	flag_reg0(
		.clk(clk),	.rst(rst),	
		.c_i(flag_ci),		.z_i(flag_zi),	.v_i(flag_vi),	.s_i(flag_si),
		.c_o(flag_co),		.z_o(flag_zo),	.v_o(flag_vo),	.s_o(flag_so));
divide div0(
		.clk(clk),	.rst(rst),
		.signed_div_i(signed_div),	.opdata1_i(div_opdata1),
		.opdata2_i(div_opdata2),	.start_i(div_start),
		.annul_i(1'b0),				
		.result_o(div_result),		.ready_o(div_ready)
);
endmodule
