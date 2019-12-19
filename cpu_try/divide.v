`include"define.v"
module divide(
	input wire clk,
	input wire rst,
	input wire signed_div_i,
	input wire[15:0] opdata1_i,
	input wire[15:0] opdata2_i,
	input wire	start_i,
	input wire annul_i,  //1时取消除法运算
	output reg[31:0] result_o,
	output reg ready_o  //除法结束
	);
	
wire[16:0] div_temp;
wire[15:0] temp;
reg[4:0]	cnt; //记录试商法进行次数，等于15则表示结束
reg[32:0]	dividend;//低16位保存被除数的中间结果，第k次迭代结束，时[k:0]保存的为当前得到的中间结果，dividend[31:k+1]保存的是被除数中还没有参与运算的数据，
//dividend 高16位是每次迭代时的被减数，所以 [31:16]
reg[1:0]		state;
reg[15:0]	divisor;		//除数
reg[15:0]	temp_op1;
reg[15:0]   temp_op2;
assign div_temp ={1'b0, dividend[31:16]}- {1'b0,divisor} ;//- {1'b0,divisor}

always@(posedge clk) begin
	if(rst==`RstEnable)	begin
		state<=`DivFree;
		ready_o<=`DivResultNotReady;
		result_o<={`ZeroHalfWord,`ZeroHalfWord};
			end
	else 	begin
		case(state)
		`DivFree:	begin
			if(start_i ==`DivStart &&annul_i==1'b0)	begin 
				if(opdata2_i ==`ZeroHalfWord)	begin
					state<=`DivByZero;
						end
				else begin
					state<=`DivOn;
					cnt<=5'b00000;
					if(signed_div_i ==1'b1 && opdata1_i[15]==1'b1)	begin  //判断有无符号
						temp_op1	= ~opdata1_i +1;			end
					else	begin		temp_op1 = opdata1_i;		end
					if(signed_div_i ==1'b1 && opdata2_i[15]==1'b1)	begin
						temp_op2	= ~opdata2_i+1;					end
					else begin  	temp_op2	= opdata2_i;	end
					dividend <= {`ZeroHalfWord,`ZeroHalfWord};
					dividend[16:1]<=temp_op1;
					divisor	<=	temp_op2;
					end
				end	
				else 	begin //没有开始除法运算
					ready_o<=`DivResultNotReady;
					result_o<={`ZeroHalfWord,`ZeroHalfWord};
					end
				end
		`DivByZero:	begin
			dividend<={`ZeroHalfWord,`ZeroHalfWord};
			state<=`DivEnd;
			end
		`DivOn:	begin
			if(annul_i	==1'b0)begin
				if(cnt!=5'b10000)	begin  //表示试商法还没结束
					if(div_temp[16]==1'b1) begin
		// div_temp ={1'b0, dividend[31:16]} - {1'b0,divisor};
		//如果dic_temp[16]为1，表示，minuend小于除数advisor,
		//将dividend向左移1位，这样将被除数没有参与运算的最高位，加入到下一次
		//迭代的被减数中，同时将0追加到中间结果。
						dividend<={dividend[31:0],1'b0};
						end
					else begin 
					//如果div_temp[16]=0,代表被减数大于等于除数
					//将减法的结果与被除数没有参与运算的最高位加入到下一次迭代
					//的被减数中，同时将1追加到中间结果
						dividend<={div_temp[15:0],dividend[15:0],1'b1};
							end
					cnt<=cnt+1;
					end	
				else begin //试商法结束
					if((signed_div_i==1'b1)&&((opdata1_i[15]^opdata2_i[15])==1'b1))	begin//两数符号不同
							dividend[15:0]<=	(~dividend[15:0]+1);							end
					if((signed_div_i==1'b1)&&((opdata1_i[15]^dividend[32])==1'b1))begin
							dividend[32:17]<=(~dividend[32:17]+1);							end
					state<=`DivEnd;
					cnt<=5'b00000;
					end
			end else	begin //annul_i为1
				state<=`DivFree;
					end
			end
			
		`DivEnd:	begin
			result_o<={dividend[32:17],dividend[15:0]};
			ready_o	<=	`DivResultReady;
			if(start_i==`DivStop)	begin
				state<=`DivFree;
				ready_o<=`DivResultNotReady;
				result_o<={`ZeroHalfWord,`ZeroHalfWord};
				end
			end
		endcase
	end
end 	



endmodule 