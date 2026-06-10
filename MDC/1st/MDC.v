`include "../RTL/HAMMING_IP.v"

module MDC (
    clk,
    rst_n,
    in_valid,
    in_data,
    in_mode,
    out_valid,
    out_data
);

input clk, rst_n, in_valid;
input [14:0] in_data;
input [8:0]  in_mode;

output reg out_valid;
output reg [206:0] out_data;

// ===================================
// HAMMING DECODE
// ===================================
wire signed [10:0] decoded_data;
wire        [4:0]  decoded_mode;

HAMMING_IP #(11) U_HAM_DATA (
    .IN_code  (in_data),
    .OUT_code (decoded_data)
);

HAMMING_IP #(5) U_HAM_MODE (
    .IN_code  (in_mode),
    .OUT_code (decoded_mode)
);

// ===================================
// FSM
// ===================================
localparam IDLE  = 4'b0001;
localparam INPUT = 4'b0010;
localparam CALC  = 4'b0100;
localparam OUT   = 4'b1000;

reg [3:0] c_s, n_s;
reg [3:0] data_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        c_s <= IDLE;
    else
        c_s <= n_s;
end

always @(*) begin
    n_s = c_s;

    case (c_s)
        IDLE: begin
            if (in_valid)
                n_s = INPUT;
            else
                n_s = IDLE;
        end

        INPUT: begin
            if (in_valid && data_cnt == 4'd15)
                n_s = CALC;
            else
                n_s = INPUT;
        end

        CALC: begin
            n_s = OUT;
        end

        OUT: begin
            n_s = IDLE;
        end

        default: begin
            n_s = IDLE;
        end
    endcase
end

// ===================================
// DATA COUNTER
// ===================================


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_cnt <= 4'd0;
    end
    else begin
        case (c_s)
            IDLE: begin
                if (in_valid)
                    data_cnt <= 4'd1;
                else
                    data_cnt <= 4'd0;
            end

            INPUT: begin
                if (in_valid) begin
                    if (data_cnt == 4'd15)
                        data_cnt <= 4'd0;
                    else
                        data_cnt <= data_cnt + 4'd1;
                end
            end

            default: begin
                data_cnt <= 4'd0;
            end
        endcase
    end
end

// ===================================
// INPUT BUFFER
// ===================================
reg signed [10:0] mat [0:15];
reg [4:0] mode_reg;

integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_reg <= 5'd0;
        for (i = 0; i < 16; i = i + 1)
            mat[i] <= 11'sd0;
    end
    else begin
        case (c_s)
            IDLE: begin
                if (in_valid) begin
                    mat[0] <= decoded_data;
                    mode_reg <= decoded_mode;
                end
            end

            INPUT: begin
                if (in_valid) begin
                    mat[data_cnt] <= decoded_data;
                end
            end
        endcase
    end
end

// ===================================
// CALC 
// ===================================
wire signed [22:0] det2_0;
wire signed [22:0] det2_1;
wire signed [22:0] det2_2;
wire signed [22:0] det2_3;
wire signed [22:0] det2_4;
wire signed [22:0] det2_5;
wire signed [22:0] det2_6;
wire signed [22:0] det2_7;
wire signed [22:0] det2_8;

det_2 U_DET2_0 (
    .data_0(mat[0]),
    .data_1(mat[1]),
    .data_2(mat[4]),
    .data_3(mat[5]),
    .result_2(det2_0)
);

det_2 U_DET2_1 (
    .data_0(mat[1]),
    .data_1(mat[2]),
    .data_2(mat[5]),
    .data_3(mat[6]),
    .result_2(det2_1)
);

det_2 U_DET2_2 (
    .data_0(mat[2]),
    .data_1(mat[3]),
    .data_2(mat[6]),
    .data_3(mat[7]),
    .result_2(det2_2)
);

det_2 U_DET2_3 (
    .data_0(mat[4]),
    .data_1(mat[5]),
    .data_2(mat[8]),
    .data_3(mat[9]),
    .result_2(det2_3)
);

det_2 U_DET2_4 (
    .data_0(mat[5]),
    .data_1(mat[6]),
    .data_2(mat[9]),
    .data_3(mat[10]),
    .result_2(det2_4)
);

det_2 U_DET2_5 (
    .data_0(mat[6]),
    .data_1(mat[7]),
    .data_2(mat[10]),
    .data_3(mat[11]),
    .result_2(det2_5)
);

det_2 U_DET2_6 (
    .data_0(mat[8]),
    .data_1(mat[9]),
    .data_2(mat[12]),
    .data_3(mat[13]),
    .result_2(det2_6)
);

det_2 U_DET2_7 (
    .data_0(mat[9]),
    .data_1(mat[10]),
    .data_2(mat[13]),
    .data_3(mat[14]),
    .result_2(det2_7)
);

det_2 U_DET2_8 (
    .data_0(mat[10]),
    .data_1(mat[11]),
    .data_2(mat[14]),
    .data_3(mat[15]),
    .result_2(det2_8)
);

wire signed [50:0] det3_0;
wire signed [50:0] det3_1;
wire signed [50:0] det3_2;
wire signed [50:0] det3_3;

det_3 U_DET3_0 (
    .data_0(mat[0]),  .data_1(mat[1]),  .data_2(mat[2]),
    .data_3(mat[4]),  .data_4(mat[5]),  .data_5(mat[6]),
    .data_6(mat[8]),  .data_7(mat[9]),  .data_8(mat[10]),
    .result_3(det3_0)
);

det_3 U_DET3_1 (
    .data_0(mat[1]),  .data_1(mat[2]),  .data_2(mat[3]),
    .data_3(mat[5]),  .data_4(mat[6]),  .data_5(mat[7]),
    .data_6(mat[9]),  .data_7(mat[10]), .data_8(mat[11]),
    .result_3(det3_1)
);

det_3 U_DET3_2 (
    .data_0(mat[4]),  .data_1(mat[5]),  .data_2(mat[6]),
    .data_3(mat[8]),  .data_4(mat[9]),  .data_5(mat[10]),
    .data_6(mat[12]), .data_7(mat[13]), .data_8(mat[14]),
    .result_3(det3_2)
);

det_3 U_DET3_3 (
    .data_0(mat[5]),  .data_1(mat[6]),  .data_2(mat[7]),
    .data_3(mat[9]),  .data_4(mat[10]), .data_5(mat[11]),
    .data_6(mat[13]), .data_7(mat[14]), .data_8(mat[15]),
    .result_3(det3_3)
);


wire signed [206:0] det4_0;

det_4 U_DET4_0 (
    .data_0(mat[0]),    .data_1(mat[1]),    .data_2(mat[2]),    .data_3(mat[3]),
    .data_4(mat[4]),    .data_5(mat[5]),    .data_6(mat[6]),    .data_7(mat[7]),
    .data_8(mat[8]),    .data_9(mat[9]),    .data_10(mat[10]),  .data_11(mat[11]),
    .data_12(mat[12]),  .data_13(mat[13]),  .data_14(mat[14]),  .data_15(mat[15]),
    .result_4(det4_0)
);

// ===================================
// CALC RESULT REGISTER
// ===================================
reg signed [206:0] result_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_reg <= 207'sd0;
    end
    else begin
        if (c_s == CALC) begin
            case (mode_reg)
                5'b00100: begin
                    // 2x2 result packing
                    result_reg <= {
                        det2_0,
                        det2_1,
                        det2_2,
                        det2_3,
                        det2_4,
                        det2_5,
                        det2_6,
                        det2_7,
                        det2_8
                    };
                end

                5'b00110: begin
                    // 3x3 result packing
                    result_reg <= {
                        3'b000,
                        det3_0,
                        det3_1,
                        det3_2,
                        det3_3
                    };
                end

                5'b10110: begin
                    // 4x4 result packing
                    result_reg <= det4_0;
                end

                default: begin
                    result_reg <= 207'sd0;
                end
            endcase
        end
    end
end

// ===================================
// OUTPUT
// ===================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
        out_data  <= 207'd0;
    end
    else begin
        if (c_s == OUT) begin
            out_valid <= 1'b1;
            out_data  <= result_reg;
        end
        else begin
            out_valid <= 1'b0;
            out_data  <= 207'd0;
        end
    end
end

endmodule

module det_2 (
    data_0,
    data_1,
    data_2,
    data_3,
    result_2
);

input signed [10:0] data_0;
input signed [10:0] data_1;
input signed [10:0] data_2;
input signed [10:0] data_3;

output signed [22:0] result_2;

wire signed [21:0] tmp1;
wire signed [21:0] tmp2;

assign tmp1 = data_0 * data_3;
assign tmp2 = data_1 * data_2;

assign result_2 = {tmp1[21], tmp1} - {tmp2[21], tmp2};

endmodule

module det_3 (
    data_0, data_1, data_2,
    data_3, data_4, data_5,
    data_6, data_7, data_8,
    result_3
);

input signed [10:0] data_0;
input signed [10:0] data_1;
input signed [10:0] data_2;
input signed [10:0] data_3;
input signed [10:0] data_4;
input signed [10:0] data_5;
input signed [10:0] data_6;
input signed [10:0] data_7;
input signed [10:0] data_8;

output signed [50:0] result_3;

wire signed [22:0] minor_0;
wire signed [22:0] minor_1;
wire signed [22:0] minor_2;

wire signed [33:0] term_0;
wire signed [33:0] term_1;
wire signed [33:0] term_2;

wire signed [50:0] term_0_ext;
wire signed [50:0] term_1_ext;
wire signed [50:0] term_2_ext;

// minor_0 = | data_4 data_5 |
//           | data_7 data_8 |
det_2 U_MINOR_0 (
    .data_0  (data_4),
    .data_1  (data_5),
    .data_2  (data_7),
    .data_3  (data_8),
    .result_2(minor_0)
);

// minor_1 = | data_3 data_5 |
//           | data_6 data_8 |
det_2 U_MINOR_1 (
    .data_0  (data_3),
    .data_1  (data_5),
    .data_2  (data_6),
    .data_3  (data_8),
    .result_2(minor_1)
);

// minor_2 = | data_3 data_4 |
//           | data_6 data_7 |
det_2 U_MINOR_2 (
    .data_0  (data_3),
    .data_1  (data_4),
    .data_2  (data_6),
    .data_3  (data_7),
    .result_2(minor_2)
);

assign term_0 = data_0 * minor_0;
assign term_1 = data_1 * minor_1;
assign term_2 = data_2 * minor_2;

// sign extension to 51 bits
assign term_0_ext = {{17{term_0[33]}}, term_0};
assign term_1_ext = {{17{term_1[33]}}, term_1};
assign term_2_ext = {{17{term_2[33]}}, term_2};

assign result_3 = term_0_ext - term_1_ext + term_2_ext;

endmodule

module det_4 (
    data_0,  data_1,  data_2,  data_3,
    data_4,  data_5,  data_6,  data_7,
    data_8,  data_9,  data_10, data_11,
    data_12, data_13, data_14, data_15,
    result_4
);

input signed [10:0] data_0;
input signed [10:0] data_1;
input signed [10:0] data_2;
input signed [10:0] data_3;
input signed [10:0] data_4;
input signed [10:0] data_5;
input signed [10:0] data_6;
input signed [10:0] data_7;
input signed [10:0] data_8;
input signed [10:0] data_9;
input signed [10:0] data_10;
input signed [10:0] data_11;
input signed [10:0] data_12;
input signed [10:0] data_13;
input signed [10:0] data_14;
input signed [10:0] data_15;

output signed [206:0] result_4;

wire signed [50:0] minor_0;
wire signed [50:0] minor_1;
wire signed [50:0] minor_2;
wire signed [50:0] minor_3;

wire signed [61:0] term_0;
wire signed [61:0] term_1;
wire signed [61:0] term_2;
wire signed [61:0] term_3;

wire signed [206:0] term_0_ext;
wire signed [206:0] term_1_ext;
wire signed [206:0] term_2_ext;
wire signed [206:0] term_3_ext;

// minor_0: remove row 0, column 0
det_3 U_MINOR_0 (
    .data_0(data_5),  .data_1(data_6),  .data_2(data_7),
    .data_3(data_9),  .data_4(data_10), .data_5(data_11),
    .data_6(data_13), .data_7(data_14), .data_8(data_15),
    .result_3(minor_0)
);

// minor_1: remove row 0, column 1
det_3 U_MINOR_1 (
    .data_0(data_4),  .data_1(data_6),  .data_2(data_7),
    .data_3(data_8),  .data_4(data_10), .data_5(data_11),
    .data_6(data_12), .data_7(data_14), .data_8(data_15),
    .result_3(minor_1)
);

// minor_2: remove row 0, column 2
det_3 U_MINOR_2 (
    .data_0(data_4),  .data_1(data_5),  .data_2(data_7),
    .data_3(data_8),  .data_4(data_9),  .data_5(data_11),
    .data_6(data_12), .data_7(data_13), .data_8(data_15),
    .result_3(minor_2)
);

// minor_3: remove row 0, column 3
det_3 U_MINOR_3 (
    .data_0(data_4),  .data_1(data_5),  .data_2(data_6),
    .data_3(data_8),  .data_4(data_9),  .data_5(data_10),
    .data_6(data_12), .data_7(data_13), .data_8(data_14),
    .result_3(minor_3)
);

assign term_0 = data_0 * minor_0;
assign term_1 = data_1 * minor_1;
assign term_2 = data_2 * minor_2;
assign term_3 = data_3 * minor_3;

assign term_0_ext = {{145{term_0[61]}}, term_0};
assign term_1_ext = {{145{term_1[61]}}, term_1};
assign term_2_ext = {{145{term_2[61]}}, term_2};
assign term_3_ext = {{145{term_3[61]}}, term_3};

assign result_4 = term_0_ext - term_1_ext + term_2_ext - term_3_ext;

endmodule
