`timescale	1ns/1ps
`include"define.v"
module cpu_try_tb();
	reg CLOCK_50;
	reg	rst;
	
//对寄存器组初始化


	//每隔10ns clk信号翻转一次，一个周期20ns 对应50mhz
initial	begin
	CLOCK_50	=	1'b0;
	forever	#50 CLOCK_50 = ~CLOCK_50;
end


initial begin
	rst	= `RstEnable;
	#195	rst	=	`RstDisable;
	#60000 $stop;
end

	//最初时刻，复位信号有效，在195ns，复位信号无效，最小SOPC运行
	top_test	top_test0(
	.clk(CLOCK_50),
	.rst(rst)
	);
endmodule 