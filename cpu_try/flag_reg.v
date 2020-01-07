`include"define.v"
module flag_reg(
		input wire clk,
		input wire rst,
		input wire c_i,
		input wire z_i,
		input wire v_i,
		input wire s_i,
		output reg c_o,
		output reg z_o,
		output reg v_o,
		output reg s_o
);
always@(posedge clk)	begin
			c_o<=1'b0;
			z_o<=1'b0;
			v_o<=1'b0;
			s_o<=1'b0;
	if(rst==`RstEnable)	begin
			c_o<=1'b0;
			z_o<=1'b0;
			v_o<=1'b0;
			s_o<=1'b0;
			end 
	else  begin 
			c_o<=c_i;
			z_o<=z_i;
			v_o<=v_i;
			s_o<=s_i;
			end 
end

endmodule 