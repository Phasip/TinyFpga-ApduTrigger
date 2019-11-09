module iso7816_trigger
/*
    This module sends a trigger signal after the 
    match_pattern is seen on the DATA line.
    No CRC/Error handling - hope for no errors!
    You need to calculate the ETS yourself from Fd,Dd in the card ATR.
    
*/
#(
    // Bytes to search for in APDU command.
    parameter MATCH_PATTERN = 'hBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB,
    // ETS as from ISO7816-3, Dd & Fd
    parameter ETS_CARD_CLK_COUNT = (2048/64)/2-1
)
(
    input CARD_CLK,  
    input DATA, 
    output TRIGGER
);
    parameter MATCH_COUNTER_BITLEN = $clog2($bits(MATCH_PATTERN)+1);
    parameter MATCH_PATTERN_MSB = $bits(MATCH_PATTERN)-1;
    
    parameter RECEIVING = 1,WAITING = 0;
    reg reset = 1;
    reg state;
    
    // How far we are in each byte transfer zero+start+8bits+parity+error+delay => 13 values
    parameter STATE_RECV_BIT_LEN=$clog2(13);
    reg [STATE_RECV_BIT_LEN-1:0] state_recv_bit;
    // Use a match counter instead of bit-shifting in data as 
    // this method requires fewer cells
    reg [MATCH_COUNTER_BITLEN-1:0] match_pattern_idx;
    reg [$clog2(ETS_CARD_CLK_COUNT+1):0] clk_counter;
    
    // Output on trigger
    assign TRIGGER = (match_pattern_idx == MATCH_PATTERN_MSB+1 && state == WAITING);

    initial
    begin
        $dumpfile("testbench_tb.vcd");
        $dumpvars(0,CARD_CLK, DATA, state, TRIGGER);
    end
    
    /*
        run each time we think a new bit is incomming
    */
    task recv_bit;
        input reg [STATE_RECV_BIT_LEN-1:0] state_recv_bit_new;
        begin
            state_recv_bit <= state_recv_bit_new;
            $display("state_recv_bit %d",state_recv_bit_new);
            case (state_recv_bit_new)
            //0 never happens
            1: begin
                if (DATA == 1) begin
                    //The first bit went wrong. Go into starting state
                    $display("First bit wrong, DATA is: %d",DATA);
                    state <= WAITING;
                end
                if (match_pattern_idx%8 != 0) begin
                    // We are not in sync, reset count
                    match_pattern_idx <= 0;
                end
            end
            2,3,4,5,6,7,8,9: begin
                $display("Data bit!");
                if (DATA == MATCH_PATTERN[match_pattern_idx]) begin
                    $display("Matching bit! %d",match_pattern_idx);
                    match_pattern_idx <= match_pattern_idx + 1;
                end 
                else begin
                    $display("Invalid BIT!");
                    match_pattern_idx <= 0;
                end
            end
            // 10 is parity bit, ignore this
            // 11 is delay
            // 12.5 is error bit
            13: 
            begin
                    state <= WAITING;
                end
            endcase
        end
    endtask
    
    /* CARD_CLK here is not the on-board clock but instead the CARD_CLK signal
    from the cardreader */
    //Note, if CARD_CLK is faster than the FPGA clock, you are in trouble
    always @(posedge CARD_CLK) begin
        if (reset) begin
            //Non-blocking should be fine, but this is cleaner.
            reset = 0;
            state = WAITING;
            state_recv_bit = 0;
            match_pattern_idx = 0;
            clk_counter = 0;
        end
        
        // Overflow guard
        if (clk_counter < ETS_CARD_CLK_COUNT) begin
            clk_counter <= clk_counter + 1;
        end else begin
            clk_counter <= 0;
        end
        
        case (state)
        RECEIVING:
            if (clk_counter == ETS_CARD_CLK_COUNT/2) begin
                //Read data in the middle of each ETS
                recv_bit(state_recv_bit + 1);
            end 
        WAITING: 
            if (DATA == 0) begin
                clk_counter <= 0;
                state <= RECEIVING;
                state_recv_bit <= 0;
            end
        endcase
    end
endmodule
