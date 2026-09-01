module Convolution (
    clk,
    rst_n,
    in_valid,
    in_ready,
    weight_valid,
    In_IFM_1,
    In_IFM_2,
    In_IFM_3,
    In_IFM_4,
    In_IFM_5,
    In_IFM_6,
    In_IFM_7,
    In_IFM_8,
    In_IFM_9,
    In_IFM_10,
    In_IFM_11,
    In_IFM_12,
    In_IFM_13,
    In_IFM_14,
    In_IFM_15,
    In_IFM_16,
    In_IFM_17,
    In_IFM_18,
    In_IFM_19,
    In_IFM_20,
    In_IFM_21,
    In_IFM_22,
    In_IFM_23,
    In_IFM_24,
    In_IFM_25,
    In_IFM_26,
    In_IFM_27,
    In_IFM_28,
    In_IFM_29,
    In_IFM_30,
    In_IFM_31,
    In_IFM_32,
    In_Weight_1,
    In_Weight_2,
    In_Weight_3,
    In_Weight_4,
    In_Weight_5,
    In_Weight_6,
    In_Weight_7,
    In_Weight_8,
    In_Weight_9,
    In_Weight_10,
    In_Weight_11,
    In_Weight_12,
    In_Weight_13,
    In_Weight_14,
    In_Weight_15,
    In_Weight_16,
    In_Weight_17,
    In_Weight_18,
    In_Weight_19,
    In_Weight_20,
    In_Weight_21,
    In_Weight_22,
    In_Weight_23,
    In_Weight_24,
    In_Weight_25,
    In_Weight_26,
    In_Weight_27,
    In_Weight_28,
    In_Weight_29,
    In_Weight_30,
    In_Weight_31,
    In_Weight_32,
    out_valid,
    Out_OFM
);

input clk;
input rst_n;
input in_valid;
input weight_valid;
input [3:0] In_IFM_1, In_IFM_2, In_IFM_3, In_IFM_4, In_IFM_5, In_IFM_6, In_IFM_7, In_IFM_8, In_IFM_9, In_IFM_10, In_IFM_11, In_IFM_12, In_IFM_13, In_IFM_14, In_IFM_15, In_IFM_16, In_IFM_17, In_IFM_18, In_IFM_19, In_IFM_20, In_IFM_21, In_IFM_22, In_IFM_23, In_IFM_24, In_IFM_25, In_IFM_26, In_IFM_27, In_IFM_28, In_IFM_29, In_IFM_30, In_IFM_31, In_IFM_32;
input [3:0] In_Weight_1, In_Weight_2, In_Weight_3, In_Weight_4, In_Weight_5, In_Weight_6, In_Weight_7, In_Weight_8, In_Weight_9, In_Weight_10, In_Weight_11, In_Weight_12, In_Weight_13, In_Weight_14, In_Weight_15, In_Weight_16, In_Weight_17, In_Weight_18, In_Weight_19, In_Weight_20, In_Weight_21, In_Weight_22, In_Weight_23, In_Weight_24, In_Weight_25, In_Weight_26, In_Weight_27, In_Weight_28, In_Weight_29, In_Weight_30, In_Weight_31, In_Weight_32;
output in_ready;
output reg out_valid;
output reg [12:0] Out_OFM;

//counter & calc
reg [2:0]   calc_cnt;
reg [12:0]  acc;
reg [3:0]   ifm0, ifm1 ,ifm2, ifm3;
reg [3:0]   w0, w1 ,w2, w3;

wire [7:0]mul_result_0;
wire [7:0]mul_result_1;
wire [7:0]mul_result_2;
wire [7:0]mul_result_3;

wire [8:0]pair_sum0;
wire [8:0]pair_sum1;
wire [9:0]group_sum;

//STORE DATA
integer idx;
reg [3:0] IFM_BUFFER[1:32];
reg [3:0] WEIGHT_BUFFER[1:32];

//FSM
localparam IDLE  = 3'd0;
localparam CALC  = 3'd1;

reg [2:0]c_s,n_s;

assign in_ready = (c_s == IDLE)? 'd1 : 'd0;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        c_s <= IDLE;
    end
    else begin
        c_s <= n_s;
    end
end

always @(*) begin
    // n_s = c_s;
    case(c_s)
        IDLE    :
        begin
            if(in_valid)begin
                n_s = CALC;            
            end
            else begin
                n_s = IDLE;
            end
        end 

        CALC    :
        begin
            if(calc_cnt == 'd7)begin
                n_s = IDLE ;
            end
            else begin
                n_s = CALC ;
            end
        end

        default :
        begin
            n_s = IDLE;
        end 
    endcase
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(idx = 1; idx < 33; idx = idx +1)begin
            IFM_BUFFER[idx] <= 3'd0;
        end
    end
    else begin
        if(in_valid)begin
        IFM_BUFFER[1] <= In_IFM_1;
        IFM_BUFFER[2] <= In_IFM_2;
        IFM_BUFFER[3] <= In_IFM_3;
        IFM_BUFFER[4] <= In_IFM_4;
        IFM_BUFFER[5] <= In_IFM_5;
        IFM_BUFFER[6] <= In_IFM_6;
        IFM_BUFFER[7] <= In_IFM_7;
        IFM_BUFFER[8] <= In_IFM_8;
        IFM_BUFFER[9] <= In_IFM_9;
        IFM_BUFFER[10] <= In_IFM_10;
        IFM_BUFFER[11] <= In_IFM_11;
        IFM_BUFFER[12] <= In_IFM_12;
        IFM_BUFFER[13] <= In_IFM_13;
        IFM_BUFFER[14] <= In_IFM_14;
        IFM_BUFFER[15] <= In_IFM_15;
        IFM_BUFFER[16] <= In_IFM_16;
        IFM_BUFFER[17] <= In_IFM_17;
        IFM_BUFFER[18] <= In_IFM_18;
        IFM_BUFFER[19] <= In_IFM_19;
        IFM_BUFFER[20] <= In_IFM_20;
        IFM_BUFFER[21] <= In_IFM_21;
        IFM_BUFFER[22] <= In_IFM_22;
        IFM_BUFFER[23] <= In_IFM_23;
        IFM_BUFFER[24] <= In_IFM_24;
        IFM_BUFFER[25] <= In_IFM_25;
        IFM_BUFFER[26] <= In_IFM_26;
        IFM_BUFFER[27] <= In_IFM_27;
        IFM_BUFFER[28] <= In_IFM_28;
        IFM_BUFFER[29] <= In_IFM_29;
        IFM_BUFFER[30] <= In_IFM_30;
        IFM_BUFFER[31] <= In_IFM_31;
        IFM_BUFFER[32] <= In_IFM_32;
        end
        end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for(idx = 1 ; idx < 33; idx = idx + 1)begin
            WEIGHT_BUFFER[idx] <= 3'd0;
        end
    end
    else begin
        if(weight_valid)begin
            WEIGHT_BUFFER[1] <= In_Weight_1;
            WEIGHT_BUFFER[2] <= In_Weight_2;
            WEIGHT_BUFFER[3] <= In_Weight_3;
            WEIGHT_BUFFER[4] <= In_Weight_4;
            WEIGHT_BUFFER[5] <= In_Weight_5;
            WEIGHT_BUFFER[6] <= In_Weight_6;
            WEIGHT_BUFFER[7] <= In_Weight_7;
            WEIGHT_BUFFER[8] <= In_Weight_8;
            WEIGHT_BUFFER[9] <= In_Weight_9;
            WEIGHT_BUFFER[10] <= In_Weight_10;
            WEIGHT_BUFFER[11] <= In_Weight_11;
            WEIGHT_BUFFER[12] <= In_Weight_12;
            WEIGHT_BUFFER[13] <= In_Weight_13;
            WEIGHT_BUFFER[14] <= In_Weight_14;
            WEIGHT_BUFFER[15] <= In_Weight_15;
            WEIGHT_BUFFER[16] <= In_Weight_16;
            WEIGHT_BUFFER[17] <= In_Weight_17;
            WEIGHT_BUFFER[18] <= In_Weight_18;
            WEIGHT_BUFFER[19] <= In_Weight_19;
            WEIGHT_BUFFER[20] <= In_Weight_20;
            WEIGHT_BUFFER[21] <= In_Weight_21;
            WEIGHT_BUFFER[22] <= In_Weight_22;
            WEIGHT_BUFFER[23] <= In_Weight_23;
            WEIGHT_BUFFER[24] <= In_Weight_24;
            WEIGHT_BUFFER[25] <= In_Weight_25;
            WEIGHT_BUFFER[26] <= In_Weight_26;
            WEIGHT_BUFFER[27] <= In_Weight_27;
            WEIGHT_BUFFER[28] <= In_Weight_28;
            WEIGHT_BUFFER[29] <= In_Weight_29;
            WEIGHT_BUFFER[30] <= In_Weight_30;
            WEIGHT_BUFFER[31] <= In_Weight_31;
            WEIGHT_BUFFER[32] <= In_Weight_32;
        end
    end
end


assign mul_result_0 = ifm0 * w0;
assign mul_result_1 = ifm1 * w1;
assign mul_result_2 = ifm2 * w2;
assign mul_result_3 = ifm3 * w3;

assign pair_sum0 = {1'b0, mul_result_0} + {1'b0, mul_result_1};
assign pair_sum1 = {1'b0, mul_result_2} + {1'b0, mul_result_3};
assign group_sum = {1'b0, pair_sum0} + {1'b0, pair_sum1};

always@(*)begin
   case(calc_cnt)
        3'd0:
        begin
            ifm0 = IFM_BUFFER[1];
            ifm1 = IFM_BUFFER[2];
            ifm2 = IFM_BUFFER[3];
            ifm3 = IFM_BUFFER[4];
            w0   = WEIGHT_BUFFER[1];
            w1   = WEIGHT_BUFFER[2];
            w2   = WEIGHT_BUFFER[3];
            w3   = WEIGHT_BUFFER[4];
        end
        3'd1:
        begin
            ifm0 = IFM_BUFFER[5];
            ifm1 = IFM_BUFFER[6];
            ifm2 = IFM_BUFFER[7];
            ifm3 = IFM_BUFFER[8];
            w0   = WEIGHT_BUFFER[5];
            w1   = WEIGHT_BUFFER[6];
            w2   = WEIGHT_BUFFER[7];
            w3   = WEIGHT_BUFFER[8];
        end
        3'd2:
        begin
            ifm0 = IFM_BUFFER[9];
            ifm1 = IFM_BUFFER[10];
            ifm2 = IFM_BUFFER[11];
            ifm3 = IFM_BUFFER[12];
            w0   = WEIGHT_BUFFER[9];
            w1   = WEIGHT_BUFFER[10];
            w2   = WEIGHT_BUFFER[11];
            w3   = WEIGHT_BUFFER[12];
        end
        3'd3:
        begin
            ifm0 = IFM_BUFFER[13];
            ifm1 = IFM_BUFFER[14];
            ifm2 = IFM_BUFFER[15];
            ifm3 = IFM_BUFFER[16];
            w0   = WEIGHT_BUFFER[13];
            w1   = WEIGHT_BUFFER[14];
            w2   = WEIGHT_BUFFER[15];
            w3   = WEIGHT_BUFFER[16];
        end
        3'd4:
        begin
            ifm0 = IFM_BUFFER[17];
            ifm1 = IFM_BUFFER[18];
            ifm2 = IFM_BUFFER[19];
            ifm3 = IFM_BUFFER[20];
            w0   = WEIGHT_BUFFER[17];
            w1   = WEIGHT_BUFFER[18];
            w2   = WEIGHT_BUFFER[19];
            w3   = WEIGHT_BUFFER[20];
        end
        3'd5:
        begin
            ifm0 = IFM_BUFFER[21];
            ifm1 = IFM_BUFFER[22];
            ifm2 = IFM_BUFFER[23];
            ifm3 = IFM_BUFFER[24];
            w0   = WEIGHT_BUFFER[21];
            w1   = WEIGHT_BUFFER[22];
            w2   = WEIGHT_BUFFER[23];
            w3   = WEIGHT_BUFFER[24];
        end
        3'd6:
        begin
            ifm0 = IFM_BUFFER[25];
            ifm1 = IFM_BUFFER[26];
            ifm2 = IFM_BUFFER[27];
            ifm3 = IFM_BUFFER[28];
            w0   = WEIGHT_BUFFER[25];
            w1   = WEIGHT_BUFFER[26];
            w2   = WEIGHT_BUFFER[27];
            w3   = WEIGHT_BUFFER[28];
        end
        3'd7:
        begin
            ifm0 = IFM_BUFFER[29];
            ifm1 = IFM_BUFFER[30];
            ifm2 = IFM_BUFFER[31];
            ifm3 = IFM_BUFFER[32];
            w0   = WEIGHT_BUFFER[29];
            w1   = WEIGHT_BUFFER[30];
            w2   = WEIGHT_BUFFER[31];
            w3   = WEIGHT_BUFFER[32];
        end
        default:
        begin
            ifm0 = 'd0;
            ifm1 = 'd0;
            ifm2 = 'd0;
            ifm3 = 'd0;
            w0   = 'd0;
            w1   = 'd0;
            w2   = 'd0;
            w3   = 'd0;
        end
   endcase 
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        calc_cnt <= 'd0;
    end
    else begin
        case(c_s)
            IDLE : begin
                calc_cnt <= 'd0;
            end

            CALC : begin
                if(calc_cnt == 'd7)begin
                    calc_cnt <= 'd0;
                end
                else begin
                    calc_cnt <= calc_cnt + 'd1;
                end
            end

            default : begin
                calc_cnt <= 'd0;
            end
        endcase
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        acc <= 13'd0;
    end
    else begin
        case(c_s)
            IDLE : begin
                acc <= 13'd0;
            end

            CALC : begin
                if(calc_cnt == 3'd7)begin
                    acc <= 13'd0;
                end
                else begin
                    acc <= acc +{{3{1'b0}}, group_sum};
                end
            end

            default : begin
                acc <= 13'd0;
            end
        endcase
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid <= 'd0;
    end
    else begin
        if((c_s == CALC) && (calc_cnt == 'd7))begin
            out_valid <= 'd1;
        end
        else begin
            out_valid <= 'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Out_OFM <= 13'd0;
    end
    else begin
        if((c_s == CALC) && (calc_cnt == 3'd7)) begin
            Out_OFM <= acc + {{3{1'b0}}, group_sum};
        end
        else begin
            Out_OFM <= Out_OFM;
        end
    end
end

endmodule
