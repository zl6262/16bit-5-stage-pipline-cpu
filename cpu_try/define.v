//全局宏定义
`define RstEnable 	1'b0 //复位信号有效
`define RstDisable 	1'b1 //复位信号无效
`define ZeroHalfWord 16'h0000 
`define WriteEnable 	1'b1
`define WriteDisable 1'b0
`define ReadEnable  	1'b1
`define ReadDisable 	1'b0
`define AluOpBus 		7:0 //译码阶段的输出aluop_o的宽度
`define AluSelBus 	2:0 //译码阶段的输出alusel_o的宽度 
`define InstValid 	1'b1
`define InstInvalid 	1'b0
`define True_v 		1'b1
`define False_v 		1'b0
`define ChipWrite 	1'b0
`define ChipRead 		1'b1
`define Stop			1'b1
`define NoStop			1'b0
/*PC指令寄存器有关的宏定义*/
`define InstAddrBus  15:0
`define InstBus      15:0
`define NoFlagUpd		1'b0
//与跳转有关
`define Branch			1'b1
`define NotBranch		1'b0	//不跳转
`define InDelaySlot 	1'b1
`define NotInDelaySlot 1'b0
/*通用寄存器组有关的宏定义*/
`define RegAddrBus  	3:0  //通用寄存器组的地址线宽度，因为定义16个寄存器
`define RegBus			15:0 //通用寄存器组的数据线宽度
`define RegWidth 		16   //通用寄存器宽度
`define DoubleRegWidth	32  //两倍的通用寄存器的宽度
`define DoubleRegBus		31:0 //两倍的通用寄存器的数据线宽度
`define RegNum 		16    //通用寄存器的数量
`define RegNumLog2	4    //通用寄存器寻址所需要的地址位数
`define NOPRegAddr	4'b0000  
`define DataAddrBus	15:0
`define DataBus		15:0

/*指令执行的宏定义*/
`define INST_1	4'b0000		//基本加减和运算
`define INST_2	4'b0010		//立即数
`define INST_3	4'b0100		//堆栈指针 // movei load /store
`define INST_4	4'b1100		//NOP
`define INST_5	4'b0011		//HILO
`define INST_6	4'b0101		//乘除 乘+
`define INST_7 4'b0001		//跳转		
//0000 基本的逻辑指令和运算指令
`define EXE_ADD	4'b0000
`define EXE_SUB	4'b0001   //0000
`define EXE_DEC	4'b0010
`define EXE_INC	4'b0011
`define EXE_CMP	4'b0110
`define EXE_AND	4'b0111
`define EXE_OR		4'b1000
`define EXE_NOT	4'b1001
`define EXE_XOR	4'b1010
`define EXE_TEST	4'b1011
`define EXE_SHL	4'b1100
`define EXE_SHR	4'b1101
`define EXE_SAR	4'b1110


//0001跳转指令
`define EXE_J		4'b0000
`define EXE_JC		4'b0001
`define EXE_JNC	4'b0010
`define EXE_JZ		4'b0011
`define EXE_JNZ	4'b0100
//0100堆栈指令
//0011 hilo指令
`define EXE_MOVE	4'b0000
`define EXE_MOVZ	4'b0001
`define EXE_MOVN	4'b0010
`define EXE_MFHI	4'b0011
`define EXE_MTHI	4'b0100
`define EXE_MFLO	4'b0101
`define EXE_MTLO	4'b0110
//0010
`define EXE_LOADH	4'b0000
`define EXE_LOADL	4'h0001   //0010
//0100
`define EXE_LOAD	4'b0001
`define EXE_STORE	4'b0010
//1100
`define EXE_NOP	4'b0000
//0101	乘除
`define EXE_MUL	4'b0000	//有符号乘法
`define EXE_MULU	4'b0001	//无符号乘法
`define EXE_DIV	4'b0010
`define EXE_DIVU	4'b0011	//结果 LO  余数HI

//ALUOP
`define EXE_ADD_OP		8'b00000000
`define EXE_SUB_OP		8'b00000010
`define EXE_CMP_OP		8'b00000110
`define EXE_AND_OP		8'b00000111
`define EXE_OR_OP			8'b00001000
`define EXE_NOT_OP		8'b00001001
`define EXE_XOR_OP		8'b00001010
`define EXE_TEST_OP		8'b00001011
`define EXE_SHL_OP		8'b00001100
`define EXE_SHR_OP		8'b00001101
`define EXE_SAR_OP		8'b00001110
`define EXE_NOP_OP		8'b11000000
//跳转
`define EXE_J_OP			8'b00010000
`define EXE_JC_OP			8'b00010001
`define EXE_JRNC			8'b00010010
`define EXE_JRZ			8'b00010011
`define EXE_JRNZ			8'b00010100
//0100 堆栈 /load /store /movei
`define EXE_LOAD_OP		8'b01000001
`define EXE_STORE_OP		8'b01000010
`define EXE_MOVEI			8'b01000011
`define EXE_PUSH_OP		8'b01000110
`define EXE_POP_OP		8'b01000111
//
`define EXE_MOVE_OP		8'b00110000
`define EXE_MOVZ_OP		8'b00110001
`define EXE_MOVN_OP		8'b00110010
`define EXE_MFHI_OP		8'b00110011
`define EXE_MTHI_OP		8'b00110100
`define EXE_MFLO_OP		8'b00110101
`define EXE_MTLO_OP		8'b00110110

//
`define EXE_MUL_OP		8'b01010000
`define EXE_MULU_OP		8'b01010001
`define EXE_DIV_OP		8'b01010010
`define EXE_DIVU_OP		8'b01010011

`define EXE_RES_LOGIC	3'b001
`define EXE_RES_SHIFT	3'b010
`define EXE_RES_MOVE		3'b011
`define EXE_RES_ARITHMETIC	3'b100
`define EXE_RES_MUL		3'b101
`define EXE_RES_NOP		3'b000
`define EXE_RES_JUMP_BRANCH	3'b110
`define EXE_RES_LOAD_STORE 3'b111
//与除法器有关的宏
`define DivFree			2'b00
`define DivByZero			2'b01
`define DivOn				2'b10
`define DivEnd				2'b11
`define DivResultReady	1'b1
`define DivResultNotReady 1'b0
`define DivStart 			1'b1
`define DivStop			1'b0
// ROM
`define InstNum	1024	//rom实际大小1kb
`define	InstMemNumLog2	10//ROM实际使用的地址总线宽度
