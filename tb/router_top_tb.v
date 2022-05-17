module router_top_tb ();

reg     clock,
        resetn,
        read_enb_0,
        read_enb_1,
        read_enb_2,
        pkt_valid;
reg [7:0] data_in = 0;

wire    valid_out_0,
        valid_out_1,
        valid_out_2,
        error,
        busy;

wire [7:0]  data_out_0,
            data_out_1,
            data_out_2;

router_top DUT(clock, resetn, read_enb_0, read_enb_1, read_enb_2, data_in, pkt_valid,
                    data_out_0, data_out_1, data_out_2, valid_out_0, valid_out_1, valid_out_2,
                    error, busy);

reg[7*20:0] string ;

parameter   THOLD = 1,
            TSETUP = 1,
            TCLOCK = 10;

parameter DECODE_ADDRESS    = 3'b000,
          LOAD_FIRST_DATA   = 3'b001,
          WAIT_TILL_EMPTY   = 3'b010,
          LOAD_DATA         = 3'b011,
          LOAD_PARITY       = 3'b100,
          FIFO_FULL_STATE   = 3'b101,
          CHECK_PARITY_ERROR= 3'b110,
          LOAD_AFTER_FULL   = 3'b111;

always@(DUT.FSM.state)begin
    case(DUT.FSM.state)
    3'b000 :  begin 
                string = "DA";  
                end
    3'b001 :  begin 
                string = "LFD";  
                end
    3'b010 :  begin 
                string = "WTE";  
                end
    3'b011 :  begin 
                string = "LD";  
                end
    3'b100 :  begin 
                string = "LP";  
                end
    3'b101 :  begin 
               string = "FFS"; 
                end
    3'b110 :  begin 
                string = "CPE";  
                end
    3'b111 :  begin 
               string = "LAF";  
                end
    endcase
end


initial begin
    {clock, read_enb_0, read_enb_1, read_enb_2, pkt_valid} <= 0;
    resetn <= 1'b1;
    forever #(TCLOCK/2) clock = ~clock;
end

task reset;
begin
    @(negedge clock)
    {clock, read_enb_0, read_enb_1, read_enb_2, pkt_valid} <= 0;
    data_in <= 'hz;
    resetn <= 1'b0;
    @(negedge clock);
    resetn <= 1'b1;
end
endtask

integer i = 0;

reg [7:0]parity = 0;

always @(i) begin
    if( i >= 15 )begin
        #50;
        if(valid_out_0)
        read_enb_0 = 1'b1;
        if(valid_out_1)
        read_enb_1 = 1'b1;
        if(valid_out_2)
        read_enb_2 = 1'b1;
    end
end

task sendpacket (input [5:0]length, input [1:0]address);
begin
    $display("Sending Packet>>>> Timestam: %2d, Packet Length: %d", $time, length);
    {i,read_enb_0,read_enb_1,read_enb_2} <= 0;
    parity = 0;
    @(negedge clock);
    wait(~busy)
    data_in = {length,address};
    parity = data_in ^ parity;
    pkt_valid =1'b1;
    @(negedge clock);
    wait(~busy)
    for(i = 0; i < length; i = i + 1) begin
        @(negedge clock);
        if(busy) begin
        wait(~busy)
        #5;
        end
        data_in = ($random)%256;
        parity = data_in ^ parity;
    end
    @(negedge clock);
    wait(~busy)
    pkt_valid = 1'b0;
    data_in = parity;
    @(negedge clock);
    if(i < 17)begin
        case(address)
            2'b00:  read_enb_0 = 1'b1;
            2'b01:  read_enb_1 = 1'b1;
            2'b10:  read_enb_2 = 1'b1;
        endcase
    end
    wait(~busy);
    @(negedge clock);
    @(negedge clock);
    data_in = 'hz;
    wait(~(valid_out_0 || valid_out_1 || valid_out_2))
    {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
    #20; 
end
endtask

task sendpacket_with_wrong_parity (input [5:0]length, input [1:0]address);
begin
    $display("Sending Packet with wrong parity>>>> Timestam: %2d, Packet Length: %d", $time, length);
    {i,read_enb_0,read_enb_1,read_enb_2} <= 0;
    parity = 0;
    @(negedge clock);
    wait(~busy)
    data_in = {length,address};
    parity = data_in ^ parity;
    pkt_valid =1'b1;
    @(negedge clock);
    wait(~busy)
    for(i = 0; i < length; i = i + 1) begin
        @(negedge clock);
        if(busy) begin
        wait(~busy)
        #5;
        end
        data_in = ($random)%256;
        parity = data_in ^ parity;
    end
    @(negedge clock);
    wait(~busy)
    pkt_valid = 1'b0;
    data_in = !parity;
    @(negedge clock);
    if(i < 17)begin
        case(address)
            2'b00:  read_enb_0 = 1'b1;
            2'b01:  read_enb_1 = 1'b1;
            2'b10:  read_enb_2 = 1'b1;
        endcase
    end
    wait(~busy);
    @(negedge clock);
    data_in = 'hz;
    @(negedge clock);
    wait(~(valid_out_0 || valid_out_1 || valid_out_2))
    {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
    #20; 
end
endtask

task sendpacket_and_read_enable_with_some_delay (input [5:0]length, input [1:0]address);
begin
    $display("Send packet with read enable delay>>>> Timestam: %2d, Packet Length: %d", $time, length);
    {i,read_enb_0,read_enb_1,read_enb_2} <= 0;
    parity = 0;
    @(negedge clock);
    wait(~busy)
    data_in = {length,address};
    parity = data_in ^ parity;
    pkt_valid =1'b1;
    @(negedge clock);
    wait(~busy)
    for(i = 0; i < length; i = i + 1) begin
        @(negedge clock);
        if(busy) begin
        wait(~busy)
        #5;
        end
        data_in = ($random)%256;
        parity = data_in ^ parity;
    end
    @(negedge clock);
    wait(~busy)
    pkt_valid = 1'b0;
    data_in = parity;
    @(negedge clock);
    if(i < 17)begin
        #50;
        case(address)
            2'b00:  read_enb_0 = 1'b1;
            2'b01:  read_enb_1 = 1'b1;
            2'b10:  read_enb_2 = 1'b1;
        endcase
    end
    wait(~busy);
    @(negedge clock);
    data_in = 'hz;
    @(negedge clock);
    wait(~(valid_out_0 || valid_out_1 || valid_out_2))
    {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
    #20; 
end
endtask

task check_timeout(input [1:0] address);
begin
    $display("Check Counter Timeout>>>> Timestam: %2d", $time);
    {i,read_enb_0,read_enb_1,read_enb_2} <= 0;
    parity = 0;
    @(negedge clock);
    wait(~busy)
    data_in = {6'd5,address};
    parity = data_in ^ parity;
    pkt_valid =1'b1;
    @(negedge clock);
    wait(~busy)
    for(i = 0; i < 5; i = i + 1) begin
        @(negedge clock);
        if(busy) begin
        wait(~busy)
        #5;
        end
        data_in = ($random)%256;
        parity = data_in ^ parity;
    end
    @(negedge clock);
    wait(~busy)
    pkt_valid = 1'b0;
    data_in = parity;
    @(negedge clock);
    wait(~busy);
    @(negedge clock);
    data_in = 'hz;
    @(negedge clock);
    wait(~(valid_out_0 || valid_out_1 || valid_out_2))
    {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
    #20; 
end
endtask

task load_payload_before_reading_prvious (input [1:0] address);
begin
    $display("Send packet to get in WTE state>>>> Timestam: %2d", $time);
    {i,read_enb_0,read_enb_1,read_enb_2} <= 0;
    parity <= 0;
    @(negedge clock);
    wait(~busy)
    data_in = {6'd8,address};
    parity = data_in ^ parity;
    pkt_valid = 1'b1;
    @(negedge clock);
    wait(~busy)
    for(i = 0; i < 8; i = i + 1) begin
        @(negedge clock);
        if(busy)begin
            wait(~busy)
            #5;
        end
        data_in = ($random)%256;
        parity = data_in^parity;
    end
    @(negedge clock);
    wait(~busy)
    pkt_valid = 1'b0;
    data_in = parity;
    @(negedge clock);
    wait(~busy)
    data_in = 'hz;
    
    #40;

    {i,read_enb_0,read_enb_1,read_enb_2} <= 0;
    parity <= 0;
    @(negedge clock);
    wait(~busy)
    data_in = {6'd8,address};
    parity = data_in ^ parity;
    pkt_valid = 1'b1;
    @(negedge clock);
    #30;
    @(negedge clock);
    case(address)
        2'b00:  read_enb_0 = 1'b1;
        2'b01:  read_enb_1 = 1'b1;
        2'b10:  read_enb_2 = 1'b1;
    endcase
    wait(~(valid_out_0 || valid_out_1 || valid_out_2))
    for(i = 0; i < 8; i = i + 1) begin
        @(negedge clock);
        if(busy)begin
            wait(~busy)
            #5;
        end
        data_in = ($random)%256;
        parity = data_in^parity;
    end
    @(negedge clock);
    wait(~busy)
    pkt_valid = 1'b0;
    data_in = parity;
    @(negedge clock);
    wait(~busy)
    @(negedge clock);
    data_in = 'hz;
    wait(~(valid_out_0 || valid_out_1 || valid_out_2))
    {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
    #20; 
end
endtask

integer iterator = 0;

task reset_from_various_state (input [1:0] address);
begin
    for(i = 0; i < 5; i = i + 1) begin 
        begin: various_states
            #20;
            $display("\n=============================================================%t",$time);
            @(posedge clock);
            #(THOLD);
            #(TCLOCK - THOLD -TSETUP);
            parity = 0;
            $write("\nDA >");
            {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
            pkt_valid = 1'b1;
            data_in = {6'd6,address};
            parity = parity^data_in;
            @(posedge clock);
            #(THOLD);
            if(DUT.FSM.state !== LOAD_FIRST_DATA)begin
                $display("Error at %t, DA > LFD", $time);
                $stop;
            end
            $write("LFD >");
            #(TCLOCK - THOLD - TSETUP);
        
            for(iterator = 0; iterator < 6'd6; iterator = iterator + 1)begin
                wait(~busy)
                data_in = ($random)%256;
                parity = parity ^ data_in;
                @(posedge clock);
                #(THOLD);
                #(TCLOCK - THOLD - TSETUP);
            end

            wait(~busy)
            pkt_valid = 1'b0;
            data_in = parity;
            @(posedge clock);
            #(THOLD);
            #(TCLOCK - THOLD - TSETUP);
            data_in = 'hz;

            #50;
            
            parity = 0;
            pkt_valid = 1'b1;
            data_in = {6'd16, address};
            parity = parity^data_in;
            @(posedge clock);
            #(THOLD);
            if( i === 0) begin
                reset;
                disable various_states;
            end
            case(address)
                2'b00:  read_enb_0 = 1'b1;
                2'b01:  read_enb_1 = 1'b1;
                2'b10:  read_enb_2 = 1'b1;
            endcase
            wait(DUT.FSM.state === LOAD_FIRST_DATA)
            {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
            if(i === 1)begin
                reset;
                disable various_states;
            end
            if(DUT.FSM.state !== LOAD_FIRST_DATA)begin
                    $display("Error at %t, WTE > LFD", $time);
                $stop;
            end
            $write("LFD >");
            #(TCLOCK - THOLD - TSETUP);
            for(iterator = 0; iterator < 16; iterator = iterator + 1) begin
                if(iterator === 0 && i === 2)begin
                    reset;
                    disable various_states;
                end
                wait(~busy)
                data_in = ($random)%256;
                parity = parity ^ data_in;
                @(posedge clock);
                #(THOLD);
                #(TCLOCK - THOLD - TSETUP);
            end
            if(i===3)begin
                reset;
                disable various_states;
            end
            case(address)
                2'b00:  read_enb_0 = 1'b1;
                2'b01:  read_enb_1 = 1'b1;
                2'b10:  read_enb_2 = 1'b1;
            endcase
            pkt_valid = 1'b0;
            data_in = parity;
            @(posedge clock);
            #(THOLD);
            #(TCLOCK - THOLD - TSETUP);
            wait(DUT.FSM.state === LOAD_PARITY)
            if(i === 4)begin
                reset;
                disable various_states;
            end
            wait(~(valid_out_0 || valid_out_1 || valid_out_2))
            {read_enb_0,read_enb_1,read_enb_2} = 3'b000;
            #20; 
            reset;
        end
    end
end
endtask



initial begin
    
    #20;
    reset;
    #20;
    {read_enb_0,read_enb_1, read_enb_2} <= 0;
    #10;
    reset_from_various_state(1);
    #20;
    sendpacket(8,1);
    #40;
    sendpacket(14,1);
    #40;
    sendpacket(15,1);
    #40;
    sendpacket(16,1);
    #40;
    sendpacket(17,1);
    #40;
    sendpacket(63,1);
    #40;
    sendpacket_with_wrong_parity(14,1);
    #40;
    sendpacket_and_read_enable_with_some_delay(14,1);
    #40;
    check_timeout(1);
    #40;
    load_payload_before_reading_prvious(1);
    #40;
    
    wait(~valid_out_0 & ~valid_out_1 & ~valid_out_2)
    #20;
    reset_from_various_state(0);
    #20;
    sendpacket(8,0);
    #40;
    sendpacket(14,0);
    #40;
    sendpacket(15,0);
    #40;
    sendpacket(16,0);
    #40;
    sendpacket(17,0);
    #40;
    sendpacket(63,0);
    #40;
    check_timeout(0);
    #40;
    sendpacket_with_wrong_parity(14,0);
    #40;
    sendpacket_and_read_enable_with_some_delay(14,0);
    #40;
    load_payload_before_reading_prvious(0);
    #40;
    wait(~valid_out_0 & ~valid_out_1 & ~valid_out_2)
    #20;
    reset_from_various_state(2);
    #20;
    sendpacket(8,2);
    #40;
    sendpacket(14,2);
    #40;
    sendpacket(15,2);
    #40;
    sendpacket(16,2);
    #40;
    sendpacket(17,2);
    #40;
    sendpacket(63,2);
    #40;
    check_timeout(2);
    #40;
    sendpacket_with_wrong_parity(14,2);
    #40;
    sendpacket_and_read_enable_with_some_delay(14,2);
    #40
    load_payload_before_reading_prvious(2);
    #40;
    wait(~valid_out_0 & ~valid_out_1 & ~valid_out_2)
    #20;
    sendpacket(15,3);
    #40;
    reset;

    pkt_valid = 1'b1;
    data_in = 8'd0;
    DUT.FIFO_0.itr = 8'd0;
    DUT.FIFO_1.itr = 8'd0;
    DUT.FIFO_2.itr = 8'd0;
    @(negedge clock);
    data_in = 8'd255;
    DUT.FIFO_0.itr = 8'd255;
    DUT.FIFO_1.itr = 8'd255;
    DUT.FIFO_2.itr = 8'd255;
    @(negedge clock);
    data_in = 8'd0;
    DUT.FIFO_0.itr = 8'd0;
    DUT.FIFO_1.itr = 8'd0;
    DUT.FIFO_2.itr = 8'd0;
    @(negedge clock);
    #20;
    reset;
    #40;
    $stop;
end

endmodule