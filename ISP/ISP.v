module ISP(
    // --- Input Signals ---
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input       in_mode,
    input [1:0] in_ratio_mode,

    // --- Output Signals ---
    output reg out_valid,
    output reg [7:0] out_data,
    
    // ----- DRAM Signals -----
    // ==================================
    // <<<< AXI write address channel >>>>
    // ==================================
    // src master
    output     [3:0]  awid_s_inf,
    output reg [31:0] awaddr_s_inf,
    output reg [2:0]  awsize_s_inf,
    output reg [1:0]  awburst_s_inf,
    output reg [7:0]  awlen_s_inf,
    output reg        awvalid_s_inf,
    // src slave
    input             awready_s_inf,
    // -----------------------------
    // ==================================
    // <<<<< AXI write data channel >>>>>
    // ==================================
    // src master
    output reg [127:0]  wdata_s_inf,
    output reg          wlast_s_inf,
    output reg          wvalid_s_inf,
    // src slave
    input               wready_s_inf,
    
    // ==================================
    // <<< AXI write response channel >>>
    // ==================================
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output reg     bready_s_inf,
    // -----------------------------
    
    // ==================================
    // <<<< AXI read address channel >>>>
    // ==================================
    // src master
    output      [3:0]   arid_s_inf, 
    output reg  [31:0]  araddr_s_inf,
    output reg  [7:0]   arlen_s_inf,
    output reg  [2:0]   arsize_s_inf,
    output reg  [1:0]   arburst_s_inf,
    output reg     arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------

    // ==================================
    // <<<<< AXI read data channel >>>>>
    // ==================================
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output reg     rready_s_inf
    
);


always@(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
        pic_no <= 'd0;
   end 
   else begin
        if(in_valid)begin
            pic_no <= in_pic_no;
        end
        else begin
            pic_no <= pic_no;
        end
   end
end


always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        mode <= 'd0;
    end
    else begin
        if(in_valid)begin
            mode <= in_mode;
        end
        else begin
            mode <= mode;
        end
    end
end


always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        ratio_mode <= 'd0;
    end
    else begin
        if(in_valid)begin
            ratio_mode <= in_ratio_mode;
        end
        else begin
            ratio_mode <= ratio_mode;
        end
    end
end


always@(*)begin
    if(in_mode)begin
        case(in_pic_no)     //auto exposure
        0:  pic_addr = 32'h10000;
        1:  pic_addr = 32'h10C00;
        2:  pic_addr = 32'h11800;
        3:  pic_addr = 32'h12400;
        4:  pic_addr = 32'h13000;
        5:  pic_addr = 32'h13C00;
        6:  pic_addr = 32'h14800;
        7:  pic_addr = 32'h15400;
        8:  pic_addr = 32'h16000;
        9:  pic_addr = 32'h16C00;
        10: pic_addr = 32'h17800;
        11: pic_addr = 32'h18400;
        12: pic_addr = 32'h19000;
        13: pic_addr = 32'h19C00;
        14: pic_addr = 32'h1A800;
        15: pic_addr = 32'h1B400;
        default: pic_addr = 0;
        endcase
    end
    else begin
        case(in_pic_no)     //auto focus
        0:  pic_addr = 32'h10000 + 416;
        1:  pic_addr = 32'h10C00 + 416;
        2:  pic_addr = 32'h11800 + 416;
        3:  pic_addr = 32'h12400 + 416;
        4:  pic_addr = 32'h13000 + 416;
        5:  pic_addr = 32'h13C00 + 416;
        6:  pic_addr = 32'h14800 + 416;
        7:  pic_addr = 32'h15400 + 416;
        8:  pic_addr = 32'h16000 + 416;
        9:  pic_addr = 32'h16C00 + 416;
        10: pic_addr = 32'h17800 + 416;
        11: pic_addr = 32'h18400 + 416;
        12: pic_addr = 32'h19000 + 416;
        13: pic_addr = 32'h19C00 + 416;
        14: pic_addr = 32'h1A800 + 416;
        15: pic_addr = 32'h1B400 + 416;
        default: pic_addr = 0;
        endcase
    end
end

endmodule