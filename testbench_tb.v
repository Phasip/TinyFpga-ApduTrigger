`timescale 1ns / 100ps
/* Module to replay pre-recorded signal from 
authenticate_SIM_ISO7816.tv
*/
module testbench();
    reg tb_clk;
    reg data,clock,tb_clk_change,tb_clk_val,data_change,data_val;
    parameter tv_file_size = 14000000;
    wire trig_output;
    reg[31:0] vectornum;
    reg[3:0]  testvectors[tv_file_size-1:0];
    
    iso7816_trigger dut(.CARD_CLK(clock), .DATA(data), .TRIGGER(trig_output) );
    always
    begin
        tb_clk= 1; #5; tb_clk= 0; #5;
    end

    initial
    begin
        $readmemb("authenticate_SIM_ISO7816.tv", testvectors);
        vectornum= 0;
    end
    
    always @(posedge tb_clk)
        begin
        {tb_clk_change,tb_clk_val,data_change,data_val} = testvectors[vectornum];
        if (tb_clk_change == 1) begin
            clock = tb_clk_val;
        end
        
        if (data_change == 1) begin
            data = data_val;
        end
        
        vectornum= vectornum+ 1;
        if (vectornum == tv_file_size-2) begin
            $finish;
        end
    end
endmodule
