module router_sync (detect_add,data_in,write_enb_reg,clock,resetn, read_enb_0, read_enb_1, read_enb_2,
                    empty_0, empty_1, empty_2, full_0, full_1, full_2, 
                    vld_out_0, vld_out_1, vld_out_2, write_enb, fifo_full, soft_reset_0, soft_reset_1,
                    soft_reset_2);
        
input wire  detect_add,
            write_enb_reg,
            clock,
            resetn,
            read_enb_0,
            read_enb_1,
            read_enb_2,
            empty_0,
            empty_1,
            empty_2,
            full_0,
            full_1,
            full_2;

input wire [1:0] data_in;

reg [1:0] address = 0;

output wire [2:0] write_enb;

output wire vld_out_0,
            vld_out_1,
            vld_out_2;
				
output reg	soft_reset_0,
            soft_reset_1,
            soft_reset_2;
				
output wire fifo_full;

reg [4:0] counter[2:0];

assign write_enb[0] = (~address[1] & ~address[0] & write_enb_reg);
assign write_enb[1] = (~address[1] & address[0] & write_enb_reg);
assign write_enb[2] = (address[1] & ~address[0] & write_enb_reg);

assign fifo_full =  full_0 || full_1 || full_2;

assign vld_out_0 = ~empty_0;
assign vld_out_1 = ~empty_1;
assign vld_out_2 = ~empty_2;

always @(counter) begin
    if(counter[0] === 30)
        soft_reset_0 = 1'b1;
    else soft_reset_0 = 1'b0;
    if(counter[1] === 30)
        soft_reset_1 = 1'b1;
    else soft_reset_1 = 1'b0;
    if(counter[2] === 30)
        soft_reset_2 = 1'b1;
    else soft_reset_2 = 1'b0;
end

always @(posedge clock) begin
    if(!resetn) begin
        counter[0] <= 0;
        counter[1] <= 0;
        counter[2] <= 0;
        address = 2'b11;
    end
    else begin
        if(detect_add)
            address = data_in;

        if(vld_out_0 ) begin
            if(read_enb_0) counter[0] <= 0;
            else begin
                if(counter [0] == 30) counter[0] <= 0;
                else counter[0] <= counter[0] + 1;
            end
        end
        if(vld_out_1) begin
            if(read_enb_1) counter[1] <= 0;
            else begin
                if(counter [1] == 30) counter[1] <= 0;
                else counter[1] <= counter[1] + 1;
            end
        end
        if(vld_out_2) begin
            if(read_enb_2) counter[2] <= 0;
            else begin
                if(counter [2] == 30) counter[2] <= 0;
                else counter[2] <= counter[2] + 1;
            end
        end
    end
end
endmodule