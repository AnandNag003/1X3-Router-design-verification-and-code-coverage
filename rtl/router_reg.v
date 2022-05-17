module router_reg (clock, resetn, pkt_valid, data_in,fifo_full,rst_int_reg,detect_add,
                    ld_state, laf_state, full_state, lfd_state,
                    parity_done, low_pkt_valid, err, dout);

input   clock,
        resetn,
        pkt_valid,
        fifo_full,
        rst_int_reg,
        detect_add,
        ld_state,
        laf_state, 
        full_state,
        lfd_state;

input wire [7:0] data_in;

output reg  parity_done = 0;
output reg low_pkt_valid = 1;
output reg  err = 0;

output reg [7:0] dout = 0;

reg [7:0] header_byte = 0;
reg [7:0] FFS_byte = 0;
reg [7:0] internal_parity_byte = 0;
reg [7:0] packet_parity_byte = 0;
reg packet_parity_loaded = 0;
wire [7:0] bus_to_dout [4:0];

wire ld_and_not_pkt_valid;

assign ld_and_not_pkt_valid = ld_state & ~pkt_valid;

//Header Byte Latching
always @(resetn, detect_add, pkt_valid)begin
    if(!resetn)begin
        header_byte <= 0;
    end
    else if(detect_add && pkt_valid)begin
        header_byte <= data_in;
    end
end

// To Latch FFS_byte
always @(posedge clock) begin
    if(!resetn)begin
        FFS_byte <= 0;
    end
    else if(ld_state && fifo_full)begin
        FFS_byte <= data_in;
    end
end

// For doing the XOR operation and stroing result in internal parity register
always @(posedge clock)begin
    if(!resetn)begin
        internal_parity_byte <= 0;
    end
    else begin
        if( lfd_state) begin
            internal_parity_byte = 0;
            internal_parity_byte <= internal_parity_byte ^header_byte;
        end
        else if(!full_state && pkt_valid && ld_state)begin
            internal_parity_byte <= internal_parity_byte ^ data_in;
        end
        else begin
            internal_parity_byte <= internal_parity_byte;
        end
	end
end

// To set/reset packet_parity_byte
always @(posedge clock) begin
    if(!resetn)begin
        packet_parity_byte <= 0;
    end
    else begin
        if(parity_done) begin
				packet_parity_byte <= data_in;
				packet_parity_loaded <= 1;
        end
		  else begin
				packet_parity_loaded <= 0;
		end
    end
end

// To set/ reset parity_done
always @(posedge clock) begin
    if(!resetn)begin
        parity_done <= 0;
    end
    else if ((ld_and_not_pkt_valid && !fifo_full) || (laf_state & low_pkt_valid && ~parity_done))begin
        parity_done <= 1;
    end
    else if(detect_add)begin
        parity_done <= 0;
    end
end

// To set/reset low_pkt_valid
always @(posedge clock) begin
    if(!resetn)begin
        low_pkt_valid <= 0;
    end
	 else if(rst_int_reg)begin
			low_pkt_valid <= 0;
		end
    else if(ld_state & ~pkt_valid)begin
        low_pkt_valid <= 1;
    end
end

//TO set/reset ERR
always @(posedge clock) begin
    if(!resetn)begin
        err <= 0;
    end
    else if(parity_done) begin
        if(data_in != internal_parity_byte)begin
            err <= 1;
        end
    end
    else begin
        err <= 0;
    end
end

//Latching Byte to DOUT  , posedge ld_state, posedge laf_state
always @(posedge clock)begin
    if(!resetn)begin
        dout <= 0;
    end
    else if(lfd_state)begin
        dout <= header_byte;
    end
    else if(ld_state & ~ fifo_full)begin
        dout <= data_in;
    end
    else if(laf_state)begin
        dout <= FFS_byte;
    end
    else
        dout <= dout;
end

endmodule