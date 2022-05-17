module router_fsm (clock, resetn, pkt_valid, parity_done, data_in, soft_reset_0, soft_reset_1, soft_reset_2,
                    fifo_full, low_pkt_valid, fifo_empty_0, fifo_empty_1, fifo_empty_2,
                    busy, detect_add, ld_state, laf_state, full_state, write_enb_reg,
                    rst_int_reg, lfd_state);
    
parameter DECODE_ADDRESS    = 3'b000,
          LOAD_FIRST_DATA   = 3'b001,
          WAIT_TILL_EMPTY   = 3'b010,
          LOAD_DATA         = 3'b011,
          LOAD_PARITY       = 3'b100,
          FIFO_FULL_STATE   = 3'b101,
          CHECK_PARITY_ERROR= 3'b110,
          LOAD_AFTER_FULL   = 3'b111;
        
input   clock,
        resetn,
        pkt_valid,
        parity_done,
        soft_reset_0,
        soft_reset_1,
        soft_reset_2,
        fifo_full,
        low_pkt_valid,
        fifo_empty_0,
        fifo_empty_1,
        fifo_empty_2;

input [1:0] data_in;

output  busy,
        detect_add,
        ld_state,
        laf_state,
        full_state,
        write_enb_reg,
        rst_int_reg,
        lfd_state;

wire reset;
wire data_in_fifo_full_mux;

assign data_in_fifo_full_mux = (~data_in[1] & ~data_in[0] & fifo_empty_0) |
                                (~data_in[1] & data_in[0] & fifo_empty_1) |
                                (data_in[1] & ~data_in[0] & fifo_empty_2);

assign reset = (~soft_reset_0 & ~soft_reset_1 & ~soft_reset_2 & resetn);

reg [2:0] state = 'dx;

always @(posedge clock) begin
    if(!reset)begin
        state <= DECODE_ADDRESS;
    end
    else begin
        case(state)
            DECODE_ADDRESS  :   begin
                                if(pkt_valid && (data_in != 2'b11)) begin
                                    if(data_in_fifo_full_mux)
                                        state <= LOAD_FIRST_DATA;
                                    else 
                                        state <= WAIT_TILL_EMPTY;
                                end
                                else state <= DECODE_ADDRESS;
                                end

            LOAD_FIRST_DATA :   begin
                                state <= LOAD_DATA;
                                end

            LOAD_DATA       :   begin
                                if(fifo_full)  state <= FIFO_FULL_STATE;
                                else if(!pkt_valid) state <= LOAD_PARITY;
                                else state <= LOAD_DATA;
                                end

            FIFO_FULL_STATE :   begin
                                if(!fifo_full) state <= LOAD_AFTER_FULL;
                                else state <= FIFO_FULL_STATE;
                                end
            
            LOAD_AFTER_FULL :   begin
                                if(!parity_done) begin
                                    if(low_pkt_valid) 
                                        state <= LOAD_PARITY;
                                    else
                                        state <= LOAD_DATA;
                                end
                                else state <= DECODE_ADDRESS;
                                end

            LOAD_PARITY     :   begin
                                state <= CHECK_PARITY_ERROR;
                                end

            CHECK_PARITY_ERROR  : begin
                                  if(fifo_full) state <= FIFO_FULL_STATE;
                                  else state <= DECODE_ADDRESS;
                                  end

            WAIT_TILL_EMPTY :   begin
                                if(data_in_fifo_full_mux) state <= LOAD_FIRST_DATA;
                                else state <= WAIT_TILL_EMPTY;
                                end
            default         :   state <= DECODE_ADDRESS;
        endcase
    end
end

// Combinational Output logic for various control signals depending upon the state
assign detect_add = (~state[2] & ~state[1] & ~state[0]);                    // In DECODE_ADDRESS

assign lfd_state = (~state[2] & ~state[1] & state[0]);                      // In LOAD_FIRST_DATA

assign busy = (~state[2] & ~state[1] & state[0]) |                          // In LOAD_FIRST_DATA
              (state[2] & ~state[1] & ~state[0]) |                          // In LOAD_PARITY
              (state[2] & ~state[1] & state[0])  |                          // In FIFO_FULL_STATE
              (~state[2] & state[1] & ~state[0]) |                          // In WAIT_TILL_EMPTY
              (state[2] & state[1] & ~state[0])  |                          // In CHECK_PARITY_ERROR
              (state[2] & state[1] & state[0]);                             // In LOAD_AFTER_FULL

assign ld_state = (~state[2] & state[1] & state[0]);                       // IN LOAD_DATA    

assign write_enb_reg = (~state[2] & state[1] & state[0]) |                 // In LOAD_DATA
                       (state[2] & ~state[1] & ~state[0]) |                 // IN LOAD_PARITY
                       (state[2] & state[1] & state[0]);                    // In LOAD_AFTER_FULL

assign full_state = (state[2] & ~state[1] & state[0]);                      // In FIFO_FULL_STATE

assign laf_state = (state[2] & state[1] & state[0]);                        // In LOAD_AFTER_FULL

assign rst_int_reg = (state[2] & state[1] & ~state[0]);                     // In CHECK_PARITY_ERROR

endmodule