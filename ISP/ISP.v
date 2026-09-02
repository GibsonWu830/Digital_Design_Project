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
//FSM parameter
localparam AUTO_FOCUS_MODE      = 1'b0;
localparam AUTO_EXPOSURE_MODE   = 1'b1;

localparam IDLE          = 6'b000000;
localparam DIN_WAIT      = 6'b000001;
localparam DIN           = 6'b000010;
localparam READ_MEM      = 6'b000100;
localparam AUTO_FOCUS    = 6'b001000;
localparam AUTO_EXPOSURE = 6'b010000;
localparam DOUT          = 6'b100000;

reg [5:0]STATE, NEXT_STATE;

//=======================================================
//================   LOOK UP TABLE  =====================
//=======================================================
always@(*)begin
    case(in_pic_no)     //auto exposure
    0:  pic_addr = 32'h10000;   //addr 10000    + 0 * 3072(byte)
    1:  pic_addr = 32'h10C00;   //addr 10000    + 1 * 3072(byte)
    2:  pic_addr = 32'h11800;   //addr 10000    + 2 * 3072(byte)
    3:  pic_addr = 32'h12400;   //addr 10000    + 3 * 3072(byte)
    4:  pic_addr = 32'h13000;   //addr 10000    + 4 * 3072(byte)
    5:  pic_addr = 32'h13C00;   //addr 10000    + 5 * 3072(byte)
    6:  pic_addr = 32'h14800;   //addr 10000    + 6 * 3072(byte)
    7:  pic_addr = 32'h15400;   //addr 10000    + 7 * 3072(byte)
    8:  pic_addr = 32'h16000;   //addr 10000    + 8 * 3072(byte)
    9:  pic_addr = 32'h16C00;   //addr 10000    + 9 * 3072(byte)
    10: pic_addr = 32'h17800;   //addr 10000    + 10 * 3072(byte)
    11: pic_addr = 32'h18400;   //addr 10000    + 11 * 3072(byte)
    12: pic_addr = 32'h19000;   //addr 10000    + 12 * 3072(byte)
    13: pic_addr = 32'h19C00;   //addr 10000    + 13 * 3072(byte)
    14: pic_addr = 32'h1A800;   //addr 10000    + 14 * 3072(byte)
    15: pic_addr = 32'h1B400;   //addr 10000    + 15 * 3072(byte)
    default: pic_addr = 0;
    endcase
end
//=======================================================
//=======================================================
//=======================================================


always@(*)begin
    case(STATE)
    IDLE            : NEXT_STATE = (in_valid) ? DIN_WAIT   :   IDLE;
    DIN_WAIT        : NEXT_STATE = DIN;
    DIN             : NEXT_STATE = (in_valid) ? DIN_WAIT   :   IDLE;
    READ_MEM        : NEXT_STATE = (in_valid) ? DIN_WAIT   :   IDLE;
    AUTO_FOCUS      : NEXT_STATE = (focus_done) ? DOUT   :   AUTO_FOCUS;
    AUTO_EXPOSURE   : NEXT_STATE = (exposure_done) ? DOUT   :   AUTO_EXPOSURE;
    DOUT            : NEXT_STATE = IDLE;
    default         : NEXT_STATE = IDLE;
    endcase
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        STATE <= IDLE;    
    end
    else begin
        STATE <= NEXT_STATE;
    end
end

reg in_mode_reg;
reg [1:0]in_ratio_mode_reg;
reg [3:0]in_pic_no_reg;
//========================================================
//==============AXI WRITE ADDRESS DEFAULT=================
//========================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        awid_s_inf      <= 'd0;
        awsize_s_inf    <= 'd0;
        awburst_s_inf   <= 'd0;
        arid_s_inf      <= 'd0;
        arsize_s_inf    <= 'd0;
        arburst_s_inf   <= 'd0;
        awaddr_s_inf    <= 'd0;
        awlen_s_inf     <= 'd0;
        bready_s_inf    <= 'd0;
    end
    else begin
        awid_s_inf      <= 'd0;
        awsize_s_inf    <= 3'b100;
        awburst_s_inf   <= 2'b01;
        arid_s_inf      <= 'd0;
        arsize_s_inf    <= 3'b100;
        arburst_s_inf   <= 2'b01;
        awaddr_s_inf    <= araddr_s_inf;
        awlen_s_inf     <= 8'd191;
        bready_s_inf    <= 1'b1;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        arlen_s_inf <= 'd0;
    end
    else if(in_valid) begin
        arlen_s_inf <= (in_mode == AUTO_EXPOSURE_MODE)? 'd191 : 'd142;
    end
    else begin
        arlen_s_inf <= arlen_s_inf;
    end
end


//========================================================
//========================================================
//========================================================

always@(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
        in_pic_no_reg <= 'd0;
   end 
   else begin
        if(in_valid)begin
            in_pic_no_reg <= in_pic_no;
        end
        else begin
            in_pic_no_reg <= in_pic_no_reg;
        end
   end
end


always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_mode_reg <= 'd0;
    end
    else begin
        if(in_valid)begin
            in_mode_reg <= in_mode;
        end
        else begin
            in_mode_reg <= in_mode_reg;
        end
    end
end


always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_ratio_mode_reg <= 'd0;
    end
    else begin
        if(in_valid && (in_mode == AUTO_EXPOSURE_MODE))begin
            in_ratio_mode_reg <= in_ratio_mode;
        end
        else begin
            in_ratio_mode_reg <= in_ratio_mode_reg;
        end
    end
end

//==========================================================
//================      OUTPUT DATA    =====================
//==========================================================
always@(posedge clk or rst_n)begin
    if(!rst_n)begin
        out_valid <= 1'b0;
    end
    else if(NEXT_STATE == DOUT)begin
        out_valid <= 1'b1;
    end
    else begin
        out_valid <= 1'b0;
    end
end



//==========================================================
//==========================================================
//==========================================================


endmodule