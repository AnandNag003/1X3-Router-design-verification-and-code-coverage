module router_fifo (clock, resetn, write_enb, soft_reset, read_enb, data_in, lfd_state,
                empty, data_out, full);

parameter MEM_WIDTH = 9;
parameter MEM_DEPTH = 16;
parameter ADD_WIDTH = 4;

input clock, 
      resetn, 
      write_enb, 
      soft_reset, 
      read_enb,
      lfd_state;
input wire [MEM_WIDTH - 2: 0] data_in;

output wire [MEM_WIDTH - 2:0] data_out;
output wire empty;
output wire full;

reg temp_lfd = 0;

wire [MEM_WIDTH-1:0] bus;

assign bus = {temp_lfd,data_in};

reg [MEM_WIDTH - 1:0] mem [MEM_DEPTH - 1:0];
reg [MEM_WIDTH - 2:0] temp = 0;

reg [6:0] counter;

reg [ADD_WIDTH :0] write_pointer = 0;
reg [ADD_WIDTH :0] read_pointer = 0;
wire last_bit_comp;

assign last_bit_comp = write_pointer[4] ~^ read_pointer[4];
assign pointer_equal = (write_pointer[0] ~^ read_pointer[0])&
                        (write_pointer[1] ~^ read_pointer[1])&
                        (write_pointer[2] ~^ read_pointer[2])&
                        (write_pointer[3] ~^ read_pointer[3]);
                        
assign empty = last_bit_comp & pointer_equal;
assign full = (~last_bit_comp) & pointer_equal;

assign data_out = (soft_reset)?'hz:temp;
reg [ADD_WIDTH:0] itr = 0;

always @(posedge clock) begin
    if((!resetn) || (soft_reset))begin
        for(itr = 0; itr < MEM_DEPTH; itr = itr + 1)
        mem[itr] <= 0;
        read_pointer <= 0;
        write_pointer <= 0;
        counter <= 0;
    end
    else begin
        if((write_enb) && (~full)) begin
            mem[write_pointer[3:0]] = {temp_lfd,data_in};
            write_pointer = write_pointer + 1;
        end

        if(~empty)begin
            if(read_enb)begin
                if(mem[read_pointer[3:0]][8] == 1) begin
                    counter <= mem[read_pointer[3:0]][7:2] + 2'd2;
                end
                else begin
                    counter <= counter - 1'b1;
                end
                temp = mem[read_pointer[3:0]][7:0];
                read_pointer = read_pointer + 1'b1;
            end
        end
        if(counter === 0)
            temp <= 'hz;
    end
    temp_lfd <= lfd_state;
end

endmodule