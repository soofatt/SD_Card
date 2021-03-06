module edge_detect(
	input clk_50,
	input clk_250k,
	output[1:0] out	
);

reg[1:0] out_bits;

assign out = out_bits;

always @(posedge clk_50)begin
	out_bits <= {out_bits[0], clk_250k};
end

endmodule