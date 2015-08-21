module init_block(
	input input_clk, //250kHz clock
	input input_clk_inv,
	input MISO_bit,
   input resend,
	output reg CS_bit,
	output reg MOSI_bit,
	output reg [15:0] response
);

localparam WAIT_74_CYCLE = 0, SEND_CMD0 = 1, READ_RESP = 2, END = 3;

reg[1:0] state, next_state;
reg[7:0] clock_counter;
reg[47:0] MOSI = 48'h400000000095;
reg[15:0] recv_data;
reg activator;

//assign response = recv_data;

always@(posedge input_clk or negedge resend)begin
	if(resend == 0) begin
		clock_counter <= 80;
		response <= 16'd0;
	end
	else begin
		state <= next_state;
		clock_counter <= clock_counter + 1;
		if(clock_counter < 147) begin
			activator <= 1;
			response <= recv_data;
		end
		else activator <= 0;
	end
end

always@(state)begin
	case(state)
		WAIT_74_CYCLE:begin
			if(clock_counter == 80)begin
				next_state = SEND_CMD0;
			end
			else begin
				next_state = WAIT_74_CYCLE;
			end
		end
		
		SEND_CMD0:begin
			if(clock_counter > 80 && clock_counter < 130)begin
				next_state = SEND_CMD0;
			end
			else begin
				next_state = READ_RESP;
			end
		end	
		
		READ_RESP:begin
			if(clock_counter > 129 && clock_counter < 147)begin
				next_state = READ_RESP;
			end
			else begin
				next_state = END;
			end
		end
		default:begin end
	endcase
end

always @(posedge input_clk_inv)begin
	if(activator == 1)begin
		recv_data <= {recv_data[14:0], MISO_bit}; 
		if(state == WAIT_74_CYCLE && clock_counter < 81)begin
			CS_bit <= 1;
			MOSI_bit <= 1;
		end
		else if(state == SEND_CMD0 && clock_counter > 80 && clock_counter < 130)begin
			CS_bit <= 0;
			MOSI_bit <= MOSI[47];
			MOSI = MOSI << 1;
		end
		else if(state == READ_RESP && clock_counter > 129 && clock_counter < 147) begin
			CS_bit <= 0;
			MOSI_bit <= 1;
			MOSI <= 48'h400000000095; //reassign MOSI reg with CMD0
		end
	end
	else begin
		CS_bit <= 1;
		MOSI_bit <= 1;
		recv_data <= 16'h0;
	end
end

endmodule
