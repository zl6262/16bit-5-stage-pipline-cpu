`include"define.v"
module regfile(
	input wire	clk,
	input wire 	rst,
//	input wire[1:0] sel,
	input wire[3:0] reg_sel,
//xie 
	input wire	we,
	input wire[`RegAddrBus]	waddr,
	input wire[`RegBus]		wdata,
// du 1
	input wire 	re1,
	input wire[`RegAddrBus]	raddr1,
	output reg[`RegBus]		rdata1,
//du2
	input wire	re2,
	input wire[`RegAddrBus]	raddr2,
	output reg[`RegBus]		rdata2,
//
	output wire[`RegBus]		regfile_data
	);

	reg[`RegBus]	regs[`RegNum-1:0];
	
always@(posedge clk)	begin
	if(rst==`RstEnable)	begin
			$readmemh("regs_reset.txt",regs);
			end
		else	begin
			if(we==`WriteEnable)	begin
					regs[waddr]	<=	wdata;
								end
				end
				end
always@(*)	begin
	if(rst==`RstEnable)	begin
			rdata1<=`ZeroHalfWord;
					end
	else if((raddr1==waddr)&&(we==`WriteEnable)&&(re1==`ReadEnable))	begin
				rdata1<=wdata;
				end
	else if(re1==`ReadEnable)	begin
				rdata1<=regs[raddr1];
				end
	else		begin
				rdata1<=`ZeroHalfWord;
				end
end
always@(*)	begin
	if(rst==`RstEnable)	begin
			rdata2<=`ZeroHalfWord;
					end
	else if((raddr2==waddr)&&(we==`WriteEnable)&&(re2==`ReadEnable))	begin
				rdata2<=wdata;
				end
	else if(re2==`ReadEnable)	begin
				rdata2<=regs[raddr2];
				end
	else		begin
				rdata2<=`ZeroHalfWord;
				end
end

//always@(*)	begin
//		if((sel==2'b00))	begin
//			reg_data	<=	regs[reg_sel];
//			end
//		else	begin
//		end
//end
assign regfile_data =  regs[reg_sel]	;
endmodule 