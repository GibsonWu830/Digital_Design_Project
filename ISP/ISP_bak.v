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
    output     [3:0]  awid_s_inf,       //FIX
    output reg [31:0] awaddr_s_inf,
    output reg [2:0]  awsize_s_inf,     //FIX
    output reg [1:0]  awburst_s_inf,    //FIX
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
    output      [3:0]   arid_s_inf,     //FIX 
    output reg  [31:0]  araddr_s_inf,
    output reg  [7:0]   arlen_s_inf,    //FIX
    output reg  [2:0]   arsize_s_inf,   //FIX
    output reg  [1:0]   arburst_s_inf,  //FIX
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
localparam READ_DRAM     = 6'b000100;
localparam AUTO_FOCUS    = 6'b001000;
localparam AUTO_EXPOSURE = 6'b010000;
localparam DOUT          = 6'b100000;

reg [5:0]STATE, NEXT_STATE;

//=======================================================
//================   LOOK UP TABLE  =====================
//=======================================================
wire ar_fire = arready_s_inf & arvalid_s_inf;
wire r_fire = rready_s_inf & rvalid_s_inf;
wire aw_fire = awready_s_inf & awvalid_s_inf;
wire w_fire = wready_s_inf & wvalid_s_inf;
wire b_fire = bready_s_inf & bvalid_s_inf;


reg [31:0]pic_addr;
reg direct_out;
reg direct_out_reg;
//=======================================================
//================   LOOK UP TABLE  =====================
//=======================================================
always@(*)begin
    case(in_pic_no_reg)     //auto exposure
    'd0:  pic_addr = 32'h10000;   //addr 10000    + 0(in_pic_no) * 3072(byte)
    'd1:  pic_addr = 32'h10C00;   //addr 10000    + 1(in_pic_no) * 3072(byte)
    'd2:  pic_addr = 32'h11800;   //addr 10000    + 2(in_pic_no) * 3072(byte)
    'd3:  pic_addr = 32'h12400;   //addr 10000    + 3(in_pic_no) * 3072(byte)
    'd4:  pic_addr = 32'h13000;   //addr 10000    + 4(in_pic_no) * 3072(byte)
    'd5:  pic_addr = 32'h13C00;   //addr 10000    + 5(in_pic_no) * 3072(byte)
    'd6:  pic_addr = 32'h14800;   //addr 10000    + 6(in_pic_no) * 3072(byte)
    'd7:  pic_addr = 32'h15400;   //addr 10000    + 7(in_pic_no) * 3072(byte)
    'd8:  pic_addr = 32'h16000;   //addr 10000    + 8(in_pic_no) * 3072(byte)
    'd9:  pic_addr = 32'h16C00;   //addr 10000    + 9(in_pic_no) * 3072(byte)
    'd10: pic_addr = 32'h17800;   //addr 10000    + 10(in_pic_no) * 3072(byte)
    'd11: pic_addr = 32'h18400;   //addr 10000    + 11(in_pic_no) * 3072(byte)
    'd12: pic_addr = 32'h19000;   //addr 10000    + 12(in_pic_no) * 3072(byte)
    'd13: pic_addr = 32'h19C00;   //addr 10000    + 13(in_pic_no) * 3072(byte)
    'd14: pic_addr = 32'h1A800;   //addr 10000    + 14(in_pic_no) * 3072(byte)
    'd15: pic_addr = 32'h1B400;   //addr 10000    + 15(in_pic_no) * 3072(byte)
    default: pic_addr = 0;
    endcase
end

wire [8:0] focus_start_idx = 'd429;
//=======================================================
//=======================================================
//=======================================================


always@(*)begin
    case(STATE)
    IDLE            : NEXT_STATE = (in_valid)       ? DIN_WAIT  :   IDLE;
    DIN_WAIT        : NEXT_STATE =  DIN;
    DIN             : NEXT_STATE = (direct_out_reg) ? DOUT      :   READ_DRAM;
    READ_DRAM       : NEXT_STATE = (read_dram_done) ? ((in_mode_reg == AUTO_FOCUS) ? AUTO_FOCUS    :   AUTO_EXPOSURE) : READ_DRAM;
    AUTO_FOCUS      : NEXT_STATE = (focus_done)     ? DOUT      :   AUTO_FOCUS;
    AUTO_EXPOSURE   : NEXT_STATE = (exposure_done)  ? DOUT      :   AUTO_EXPOSURE;
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

//========================================================
//========================================================
//========================================================

always @(posedeg clk or rst_n)begin
    if(!rst_n)begin
        arlen_s_inf <= 'd0;
    end
    else if(in_valid)begin
        arlen_s_inf <= (in_mode == AUTO_EXPOSURE_MODE)? 'd191 : 'd142
    end
    else begin
        arlen_s_inf <= 'd0;
    end
end

always@(posedge clk or rst_n)begin
    if(!rst_n)begin
        araddr_s_inf <= 'd0;
    end
    else if(in_mode_reg == AUTO_FOCUS_MODE)begin
        araddr_s_inf <= pic_addr + focus_start_idx; 
    end
    else begin
        araddr_s_inf <= pic_addr;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        arvalid_s_inf <= 1'b0;
    end
    else if(STATE == DIN && !direct_out_reg)begin
        arvalid_s_inf <= 1'b1;
    end
    else if(ar_fire)begin
        arvalid_s_inf <= 1'b0;
    end
    else begin
        arvalid_s_inf <= arvalid_s_inf;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rready_s_inf <= 1'b0;
    end
    else if(ar_fire)begin
        rready_s_inf <= 1'b1;
    end
    else begin
        rready_s_inf <= 1'b0;
    end
end

always@(posedge clk or rst_n)begin
    if(!rst_n)begin
        awvalid_s_inf <= 1'b0;
    end
    else if(aw_fire)begin
        awvalid_s_inf <= 1'b0;
    end
    else if(in_valid_reg & ~direct_out & in_mode_reg == AUTO_EXPOSURE_MODE) begin
        awvalid_s_inf <= 1'b1;
    end
end

always @(posedge clk) begin
    if(state == IDLE) begin
        wdata_dly_count <= 'd0;
    end
    else if(aw_shake | wdata_dly_count !='d0) begin
        wdata_dly_count <= (wdata_dly_count == 'd3) ? 'd3 : (wdata_dly_count + 'd1);
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wvalid_s_inf <= 'd0;
    end
    else if(rvalid_s_inf & in_mode_reg == AUTO_EXPOSURE_MODE) begin // r_shake
        wvalid_s_inf <= 'd1;
    end
    else if(wdata_dly_count == 'd3) begin
        wvalid_s_inf <= 'd0;
    end
    else if(in_valid_reg & in_mode_reg == AUTO_EXPOSURE_MODE) begin // in_valid_reg & ~direct_out & in_mode_reg == EXPOSURE_MODE
        wvalid_s_inf <= 'd1;
    end
end

always@(posedge clk or rst_n)begin
    if(!rst_n)begin
        wlast_s_inf <= 1'b0;
    end
    else if(channel_cnt == 'd2 & in_cnt == 'd63)begin
        wlast_s_inf <= 1'b1;
    end
    else begin
        wlast_s_inf <= 1'b0;
    end
end

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