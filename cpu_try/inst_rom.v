`include"define.v"
module inst_rom(
	input wire 		we,
	input wire[`InstAddrBus]	addr,
	inout [`InstBus]			inst
);
	reg[`RegBus]	data_in;
	reg[`RegBus]	data_out;

//定义一个数组，大小为INStNUM，元素宽度为INnstBus
	reg[`InstBus]	inst_mem[0:`InstNum-1];
	//使用文件Inst)rom.data初始化指令存储器
	initial $readmemh ("inst_test1.txt",inst_mem);
	//当复位信号无效时，依据输入的地址，输出指令存储器rom中的对应元素
	always@(*)	begin
		if(we==`ChipRead)	begin
			data_out	<=inst_mem[addr[`InstMemNumLog2+1:1]];
			end
		else	begin
			inst_mem[addr[`InstMemNumLog2+1:1]]<= data_in;//一个地址对应两个字节数据，所以从第二位开始
		end
	end
	//rom输出时 
	assign inst = (we==`ChipRead)? data_out:16'hzzzz;
	always@(*)
		begin
		data_in <=inst;
		end

endmodule 