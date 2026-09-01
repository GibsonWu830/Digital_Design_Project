`timescale 1ns/1ps

`include "../TB/conv_if.sv"
`include "../TB/conv_transaction.sv"
`include "../TB/generator.sv"
`include "../TB/driver.sv"
`include "../TB/monitor.sv"
`include "../TB/scoreboard.sv"
`include "../RTL/Convolution.v"

module tb_top;

    parameter PAT_NUM = 99;
    int output_count;
    logic clk;

    conv_if intf(clk);

    mailbox#(conv_transaction) gen2drv;
    mailbox#(conv_transaction) drv2scb;
    mailbox#(conv_transaction) mon2scb;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    //----------------------------
    //------------CLK-------------
    //----------------------------
    initial begin
        clk = 1'b0;    
    end 
    always #5 clk = !clk;

    // ------------------------------------------------
    // DUT
    // ------------------------------------------------
    Convolution u_Convolution (
        .clk          (clk),
        .rst_n        (intf.rst_n),

        .in_valid     (intf.in_valid),
        .weight_valid (intf.weight_valid),
        .in_ready     (intf.in_ready),

        .In_IFM_1  (intf.ifm[1]),
        .In_IFM_2  (intf.ifm[2]),
        .In_IFM_3  (intf.ifm[3]),
        .In_IFM_4  (intf.ifm[4]),
        .In_IFM_5  (intf.ifm[5]),
        .In_IFM_6  (intf.ifm[6]),
        .In_IFM_7  (intf.ifm[7]),
        .In_IFM_8  (intf.ifm[8]),
        .In_IFM_9  (intf.ifm[9]),
        .In_IFM_10 (intf.ifm[10]),
        .In_IFM_11 (intf.ifm[11]),
        .In_IFM_12 (intf.ifm[12]),
        .In_IFM_13 (intf.ifm[13]),
        .In_IFM_14 (intf.ifm[14]),
        .In_IFM_15 (intf.ifm[15]),
        .In_IFM_16 (intf.ifm[16]),
        .In_IFM_17 (intf.ifm[17]),
        .In_IFM_18 (intf.ifm[18]),
        .In_IFM_19 (intf.ifm[19]),
        .In_IFM_20 (intf.ifm[20]),
        .In_IFM_21 (intf.ifm[21]),
        .In_IFM_22 (intf.ifm[22]),
        .In_IFM_23 (intf.ifm[23]),
        .In_IFM_24 (intf.ifm[24]),
        .In_IFM_25 (intf.ifm[25]),
        .In_IFM_26 (intf.ifm[26]),
        .In_IFM_27 (intf.ifm[27]),
        .In_IFM_28 (intf.ifm[28]),
        .In_IFM_29 (intf.ifm[29]),
        .In_IFM_30 (intf.ifm[30]),
        .In_IFM_31 (intf.ifm[31]),
        .In_IFM_32 (intf.ifm[32]),

        .In_Weight_1  (intf.weight[1]),
        .In_Weight_2  (intf.weight[2]),
        .In_Weight_3  (intf.weight[3]),
        .In_Weight_4  (intf.weight[4]),
        .In_Weight_5  (intf.weight[5]),
        .In_Weight_6  (intf.weight[6]),
        .In_Weight_7  (intf.weight[7]),
        .In_Weight_8  (intf.weight[8]),
        .In_Weight_9  (intf.weight[9]),
        .In_Weight_10 (intf.weight[10]),
        .In_Weight_11 (intf.weight[11]),
        .In_Weight_12 (intf.weight[12]),
        .In_Weight_13 (intf.weight[13]),
        .In_Weight_14 (intf.weight[14]),
        .In_Weight_15 (intf.weight[15]),
        .In_Weight_16 (intf.weight[16]),
        .In_Weight_17 (intf.weight[17]),
        .In_Weight_18 (intf.weight[18]),
        .In_Weight_19 (intf.weight[19]),
        .In_Weight_20 (intf.weight[20]),
        .In_Weight_21 (intf.weight[21]),
        .In_Weight_22 (intf.weight[22]),
        .In_Weight_23 (intf.weight[23]),
        .In_Weight_24 (intf.weight[24]),
        .In_Weight_25 (intf.weight[25]),
        .In_Weight_26 (intf.weight[26]),
        .In_Weight_27 (intf.weight[27]),
        .In_Weight_28 (intf.weight[28]),
        .In_Weight_29 (intf.weight[29]),
        .In_Weight_30 (intf.weight[30]),
        .In_Weight_31 (intf.weight[31]),
        .In_Weight_32 (intf.weight[32]),

        .out_valid (intf.out_valid),
        .Out_OFM   (intf.Out_OFM)
    );
    // ------------------------------------------------
    // Waveform
    // ------------------------------------------------
    initial begin
        $fsdbDumpfile("conv_tb.fsdb");
        $fsdbDumpvars(0, "+mda");
    end

    // ------------------------------------------------
    // Start verification environment
    // ------------------------------------------------
    initial begin

    gen2drv = new(1);

    drv2scb = new();
    mon2scb = new();


    gen = new(gen2drv, PAT_NUM);
    drv = new(intf, gen2drv, drv2scb);
    mon = new(intf,mon2scb);
    scb = new(drv2scb, mon2scb, PAT_NUM);


    fork
        gen.run();
        drv.run();
        mon.run();
        scb.run();
    join_none
end

initial begin

    wait(scb.done == 1'b1);

    if(scb.fail_num == 0) begin
        $display("========================================");
        $display("       ALL PATTERNS PASS");
        $display("========================================");
        $finish;
    end
    else begin
        $fatal(1, "[TB] Verification failed. fail_num = %0d",
               scb.fail_num);
    end

end

parameter int MAX_CYCLES = PAT_NUM * 100;

initial begin

    repeat(MAX_CYCLES) @(posedge clk);

    if(scb.done == 1'b0) begin
        $fatal(1,
               "[TB] TIMEOUT: only checked %0d / %0d patterns",
               scb.checked_num,
               PAT_NUM);
    end

end

    

endmodule
