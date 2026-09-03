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


localparam AUTO_FOCUS_MODE      = 1'b0;
localparam AUTO_EXPOSURE_MODE   = 1'b1;


localparam IDLE         = 3'd0;
localparam WAIT_DRAM    = 3'd1;
localparam DRAM_READ    = 3'd2;
localparam DRAM_WRITE   = 3'd3;
localparam EXPOSE_SKIP  = 3'd4;
localparam PREOUT       = 3'd5;
localparam OUT          = 3'd6;


always@(*)begin
    case(state)
    //IDLE need to complete
    IDLE: n_state = WAIT_DRAM;
    WAIT_DRAM :
       n_state = rvalid_s_inf ? DRAM_READ : WAIT_DRAM; 
    DRAM_READ :
        if(rvalid_s_inf)
            n_state = DRAM_READ;
        else if (in_mode_reg)
            n_state = DRAM_WRITE;
        else 
            n_state = PREOUT;
    DRAM_WRITE : 
        wlast_s_inf ? PREOUT : DRAM_WRITE
    EXPOSE_SKIP : 
        n_state = OUT; 
    PREOUT : 
        n_state = OUT
    OUT : 
        n_state = IDLE;
    default : 
        n_state = IDLE; 
    endcase
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= IDLE;
    end
    else begin
        state <= n_state;
    end
end
//mode1
always@(posedge clk)begin
    if(rvalid_s_inf || wready_s_inf)begin
        expose_fifo <= {expose_fifo[255:0], rdata_s_inf};
    end
    else begin
        expose_fifo <= expose_fifo;
    end
end

always@(*)begin
    case(in_ratio_mode_reg)
    0:
    begin
        exposure[7:0]     = expose_fifo[263:256] >> 2;  
        exposure[15:8]    = expose_fifo[271:264] >> 2;  
        exposure[23:16]   = expose_fifo[279:272] >> 2;  
        exposure[31:24]   = expose_fifo[287:280] >> 2;  
        exposure[39:32]   = expose_fifo[295:288] >> 2;  
        exposure[47:40]   = expose_fifo[303:296] >> 2;  
        exposure[55:48]   = expose_fifo[311:304] >> 2;  
        exposure[63:56]   = expose_fifo[319:312] >> 2;  
        exposure[71:64]   = expose_fifo[327:320] >> 2;  
        exposure[79:72]   = expose_fifo[335:328] >> 2;  
        exposure[87:80]   = expose_fifo[343:336] >> 2;  
        exposure[95:88]   = expose_fifo[351:344] >> 2;  
        exposure[103:96]  = expose_fifo[359:352] >> 2;  
        exposure[111:104] = expose_fifo[367:360] >> 2;  
        exposure[119:112] = expose_fifo[375:368] >> 2;  
        exposure[127:120] = expose_fifo[383:376] >> 2; 
    end
    1: 
    begin
        exposure[7:0]     = expose_fifo[263:256] >> 1;
        exposure[15:8]    = expose_fifo[271:264] >> 1;
        exposure[23:16]   = expose_fifo[279:272] >> 1;
        exposure[31:24]   = expose_fifo[287:280] >> 1;
        exposure[39:32]   = expose_fifo[295:288] >> 1;
        exposure[47:40]   = expose_fifo[303:296] >> 1;
        exposure[55:48]   = expose_fifo[311:304] >> 1;
        exposure[63:56]   = expose_fifo[319:312] >> 1;
        exposure[71:64]   = expose_fifo[327:320] >> 1;
        exposure[79:72]   = expose_fifo[335:328] >> 1;
        exposure[87:80]   = expose_fifo[343:336] >> 1;
        exposure[95:88]   = expose_fifo[351:344] >> 1;
        exposure[103:96]  = expose_fifo[359:352] >> 1;
        exposure[111:104] = expose_fifo[367:360] >> 1;
        exposure[119:112] = expose_fifo[375:368] >> 1;
        exposure[127:120] = expose_fifo[383:376] >> 1;
    end
    2: 
        exposure = expose_fifo[383:256];
    3:
    begin
        exposure[7:0]     = (expose_fifo[263])  ? 8'd255 : expose_fifo[263:256] << 1;
        exposure[15:8]    = (expose_fifo[271])  ? 8'd255 : expose_fifo[271:264] << 1;
        exposure[23:16]   = (expose_fifo[279])  ? 8'd255 : expose_fifo[279:272] << 1;
        exposure[31:24]   = (expose_fifo[287])  ? 8'd255 : expose_fifo[287:280] << 1;
        exposure[39:32]   = (expose_fifo[295])  ? 8'd255 : expose_fifo[295:288] << 1;
        exposure[47:40]   = (expose_fifo[303])  ? 8'd255 : expose_fifo[303:296] << 1;
        exposure[55:48]   = (expose_fifo[311])  ? 8'd255 : expose_fifo[311:304] << 1;
        exposure[63:56]   = (expose_fifo[319])  ? 8'd255 : expose_fifo[319:312] << 1;
        exposure[71:64]   = (expose_fifo[327])  ? 8'd255 : expose_fifo[327:320] << 1;
        exposure[79:72]   = (expose_fifo[335])  ? 8'd255 : expose_fifo[335:328] << 1;
        exposure[87:80]   = (expose_fifo[343])  ? 8'd255 : expose_fifo[343:336] << 1;
        exposure[95:88]   = (expose_fifo[351])  ? 8'd255 : expose_fifo[351:344] << 1;
        exposure[103:96]  = (expose_fifo[359])  ? 8'd255 : expose_fifo[359:352] << 1;
        exposure[111:104] = (expose_fifo[367])  ? 8'd255 : expose_fifo[367:360] << 1;
        exposure[119:112] = (expose_fifo[375])  ? 8'd255 : expose_fifo[375:368] << 1;
        exposure[127:120] = (expose_fifo[383])  ? 8'd255 : expose_fifo[383:376] << 1;
    end
    default: exposure = 0; 
    endcase
end

// grayscale
always @(*) begin
    case(pic_channel)
    0,2:
    begin
        gray_reg[7:0]     = camera_mode ? exposure[7:0]   >> 2 : dram_data[7:0]   >> 2;
        gray_reg[15:8]    = camera_mode ? exposure[15:8]  >> 2 : dram_data[15:8]  >> 2;
        gray_reg[23:16]   = camera_mode ? exposure[23:16] >> 2 : dram_data[23:16] >> 2;
        gray_reg[31:24]   = camera_mode ? exposure[31:24] >> 2 : dram_data[31:24] >> 2;
        gray_reg[39:32]   = exposure[39:32]   >> 2;
        gray_reg[47:40]   = exposure[47:40]   >> 2;
        gray_reg[55:48]   = exposure[55:48]   >> 2;
        gray_reg[63:56]   = exposure[63:56]   >> 2;
        gray_reg[71:64]   = exposure[71:64]   >> 2;
        gray_reg[79:72]   = exposure[79:72]   >> 2;
        gray_reg[87:80]   = exposure[87:80]   >> 2;
        gray_reg[95:88]   = exposure[95:88]   >> 2;
        gray_reg[103:96]  = exposure[103:96]  >> 2;
        gray_reg[111:104] = exposure[111:104] >> 2;
        gray_reg[119:112] = exposure[119:112] >> 2;
        gray_reg[127:120] = exposure[127:120] >> 2;
    end
    1: 
    begin
        gray_reg[7:0]     = camera_mode ? exposure[7:0]   >> 1 : dram_data[7:0]   >> 1;
        gray_reg[15:8]    = camera_mode ? exposure[15:8]  >> 1 : dram_data[15:8]  >> 1;
        gray_reg[23:16]   = camera_mode ? exposure[23:16] >> 1 : dram_data[23:16] >> 1;
        gray_reg[31:24]   = camera_mode ? exposure[31:24] >> 1 : dram_data[31:24] >> 1;
        gray_reg[39:32]   = exposure[39:32]   >> 1;
        gray_reg[47:40]   = exposure[47:40]   >> 1;
        gray_reg[55:48]   = exposure[55:48]   >> 1;
        gray_reg[63:56]   = exposure[63:56]   >> 1;
        gray_reg[71:64]   = exposure[71:64]   >> 1;
        gray_reg[79:72]   = exposure[79:72]   >> 1;
        gray_reg[87:80]   = exposure[87:80]   >> 1;
        gray_reg[95:88]   = exposure[95:88]   >> 1;
        gray_reg[103:96]  = exposure[103:96]  >> 1;
        gray_reg[111:104] = exposure[111:104] >> 1;
        gray_reg[119:112] = exposure[119:112] >> 1;
        gray_reg[127:120] = exposure[127:120] >> 1;
    end
    default: gray_reg = 0;
    endcase

// grayscale value sum (same channel)
assign gray_add = gray_reg[7:0] + gray_reg[15:8] + gray_reg[23:16] + gray_reg[31:24] + 
                  gray_reg[39:32] + gray_reg[47:40] + gray_reg[55:48] + gray_reg[63:56] + 
                  gray_reg[71:64] + gray_reg[79:72] + gray_reg[87:80] + gray_reg[95:88] + 
                  gray_reg[103:96]+ gray_reg[111:104] + gray_reg[119:112] + gray_reg[127:120];

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        gray_sum <= 0;
    else if(wvalid_delay2)          // ...important!
        gray_sum <= gray_sum + gray_add;
    else if(c_s == s_IDLE)
        gray_sum <= 0;
        
end
assign gray_avg = gray_sum >> 10;

// picture zero detection
// 1: keep auto exposure
// 0: picture all zero skip to output 
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pic_expose_valid <= 16'b1111111111111111; 
    else if(n_s == s_DRAM_READ && camera_mode)
    begin
        if(exposure == 0)
            pic_expose_valid[pic_no] <= 0;     
        else
            pic_expose_valid[pic_no] <= 1;    
    end   
end


//read address scope
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        arvalid_s_inf <= 'd0;
    end
    else if(in_valid && n_state == WAIT_DRAM)begin
        arvalid_s_inf <= 'd1;
    end
    else begin
        arvalid_s_inf <= 'd1;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        araddr_s_inf <= 'd0;
    end
    else if(in_valid) begin
        araddr_s_inf <= pic_addr;
    end
    else begin
        araddr_s_inf <= araddr_s_inf;
    end
end
//read data scope
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rready_s_inf <= 'd0;
    end
    else begin
        rready_s_inf <= 'd1;
    end
end
//write address scope



//write data scope




// ==========================================
//                AXI default 
// ==========================================
assign awid_s_inf     =  4'b0;
assign arid_s_inf     =  4'b0; 

// read length
always @(*) begin
    if(!rst_n)
        arlen_s_inf   = 0;
    else if(camera_mode)
        arlen_s_inf   = 8'd191;       // 64*3 -1
    else
        arlen_s_inf   = 8'd139;       // 64*2+38-26 -1

end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        awsize_s_inf  <= 0;
        arsize_s_inf  <= 0;
        awburst_s_inf  <= 0;
        arburst_s_inf  <= 0;
        // arlen_s_inf   <= 0;
        awlen_s_inf   <= 0;
        bready_s_inf  <= 0;
    end
    else
    begin
        awsize_s_inf  <= 3'b100;       // 1 transfer 16 bytes
        arsize_s_inf  <= 3'b100;       // 1 transfer 16 bytes
        awburst_s_inf  <= 2'b01;       // INCR mode
        arburst_s_inf  <= 2'b01;       // INCR mode
        // arlen_s_inf   <= 8'd191;       // 64*3 -1
        awlen_s_inf   <= 8'd191;       // 64*3 -1
        bready_s_inf  <= 1'b1;
    end
end
//=================================================================================================
//                                            Output  
//=================================================================================================

//=================================================================================================
//                                            Input  
//=================================================================================================

always@(posedge clk or rst_n)begin
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

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_ratio_mode_reg <= 'd0;
    end
    else begin
        if(in_valid)begin
            in_ratio_mode_reg <= in_ratio_mode;
        end
        else begin
            in_ratio_mode_reg <= in_ratio_mode_reg;
        end
    end
end

always@(*)begin
    if(in_mode)begin
        case(in_pic_no)
        0 : pic_addr = 32'h10000;
        1 : pic_addr = 32'h10C00;
        2 : pic_addr = 32'h11800;
        3 : pic_addr = 32'h12400;
        4 : pic_addr = 32'h13000;
        5 : pic_addr = 32'h13C00;
        6 : pic_addr = 32'h14800;
        7 : pic_addr = 32'h15400;
        8 : pic_addr = 32'h16000;
        9 : pic_addr = 32'h16C00;
        10 : pic_addr = 32'h17800;
        11 : pic_addr = 32'h18400;
        12 : pic_addr = 32'h19000;
        13 : pic_addr = 32'h19C00;
        14 : pic_addr = 32'h1A800;
        15 : pic_addr = 32'h18400;
        default: pic_addr = 'd0;
        endcase
    end
    else begin
        case(in_pic_no)
        0 : pic_addr = 32'h10000 + 416;
        1 : pic_addr = 32'h10C00 + 416;
        2 : pic_addr = 32'h11800 + 416;
        3 : pic_addr = 32'h12400 + 416;
        4 : pic_addr = 32'h13000 + 416;
        5 : pic_addr = 32'h13C00 + 416;
        6 : pic_addr = 32'h14800 + 416;
        7 : pic_addr = 32'h15400 + 416;
        8 : pic_addr = 32'h16000 + 416;
        9 : pic_addr = 32'h16C00 + 416;
        10 : pic_addr = 32'h17800 + 416;
        11 : pic_addr = 32'h18400 + 416;
        12 : pic_addr = 32'h19000 + 416;
        13 : pic_addr = 32'h19C00 + 416;
        14 : pic_addr = 32'h1A800 + 416;
        15 : pic_addr = 32'h18400 + 416;
        default: pic_addr = 'd0;
        endcase
    end    
end
endmodule