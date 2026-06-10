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

//=====================================================
// Hamming Decode
//=====================================================
wire signed [10:0] decoded_data;
wire [4:0] decoded_mode;

HAMMING_IP #(11) U_HAM_DATA (
    .IN_code  (in_data),
    .OUT_code (decoded_data)
);

HAMMING_IP #(5) U_HAM_MODE (
    .IN_code  (in_mode),
    .OUT_code (decoded_mode)
);

//=====================================================
// FSM
//=====================================================
localparam IDLE  = 3'd0;
localparam INPUT = 3'd1;
localparam PREP2 = 3'd2;
localparam CALC3 = 3'd3;
localparam CALC4 = 3'd4;
localparam OUT   = 3'd5;

reg [2:0] c_s, n_s;

reg [3:0] data_cnt;
reg [3:0] prep_cnt;
reg [2:0] calc3_cnt;
reg [2:0] calc4_cnt;

reg signed [10:0] mat [0:15];
reg [4:0] mode_reg;

wire mode_2x2 = (mode_reg == 5'b00100);
wire mode_3x3 = (mode_reg == 5'b00110);
wire mode_4x4 = (mode_reg == 5'b10110);

//=====================================================
// Intermediate storage
//=====================================================
reg signed [22:0] m2 [0:8];
reg signed [22:0] sp [0:3];
reg signed [22:0] x03;

reg signed [34:0] r3  [0:3];
reg signed [34:0] cof [0:3];

reg signed [47:0] acc4;
reg signed [47:0] result4;

//=====================================================
// Done signals
//=====================================================
wire prep2_done;
wire calc3_done;
wire calc4_done;

assign prep2_done = mode_2x2 ? (prep_cnt == 4'd8)  :
                    mode_3x3 ? (prep_cnt == 4'd12) :
                    mode_4x4 ? (prep_cnt == 4'd13) :
                               1'b1;

assign calc3_done = (calc3_cnt == 3'd3);
assign calc4_done = (calc4_cnt == 3'd3);

//=====================================================
// FSM transition
//=====================================================
always @(*) begin
    n_s = c_s;

    case (c_s)
        IDLE: begin
            if (in_valid)
                n_s = INPUT;
        end

        INPUT: begin
            if (in_valid && data_cnt == 4'd15)
                n_s = PREP2;
        end

        PREP2: begin
            if (prep2_done) begin
                if (mode_2x2)
                    n_s = OUT;
                else
                    n_s = CALC3;
            end
        end

        CALC3: begin
            if (calc3_done) begin
                if (mode_3x3)
                    n_s = OUT;
                else
                    n_s = CALC4;
            end
        end

        CALC4: begin
            if (calc4_done)
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

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        c_s <= IDLE;
    else
        c_s <= n_s;
end

//=====================================================
// Input buffer
//=====================================================
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_cnt <= 4'd0;
        mode_reg <= 5'd0;

        for (i = 0; i < 16; i = i + 1)
            mat[i] <= 11'sd0;
    end
    else begin
        if (c_s == IDLE) begin
            data_cnt <= 4'd0;
        end

        if (in_valid) begin
            mat[data_cnt] <= decoded_data;

            if (data_cnt == 4'd0)
                mode_reg <= decoded_mode;

            if (data_cnt != 4'd15)
                data_cnt <= data_cnt + 4'd1;
        end
    end
end

//=====================================================
// PREP2 counter
//=====================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        prep_cnt <= 4'd0;
    else if (c_s == PREP2) begin
        if (prep2_done)
            prep_cnt <= 4'd0;
        else
            prep_cnt <= prep_cnt + 4'd1;
    end
    else
        prep_cnt <= 4'd0;
end

//=====================================================
// CALC3 / CALC4 counters
//=====================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        calc3_cnt <= 3'd0;
    else if (c_s == CALC3) begin
        if (calc3_done)
            calc3_cnt <= 3'd0;
        else
            calc3_cnt <= calc3_cnt + 3'd1;
    end
    else
        calc3_cnt <= 3'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        calc4_cnt <= 3'd0;
    else if (c_s == CALC4) begin
        if (calc4_done)
            calc4_cnt <= 3'd0;
        else
            calc4_cnt <= calc4_cnt + 3'd1;
    end
    else
        calc4_cnt <= 3'd0;
end

//=====================================================
// Shared 2x2 DET engine
//=====================================================
reg signed [10:0] det_a;
reg signed [10:0] det_b;
reg signed [10:0] det_c;
reg signed [10:0] det_d;

wire signed [22:0] det_out;

DET U_DET (
    .in1(det_a),
    .in2(det_d),
    .in3(det_b),
    .in4(det_c),
    .out(det_out)
);

always @(*) begin
    det_a = 11'sd0;
    det_b = 11'sd0;
    det_c = 11'sd0;
    det_d = 11'sd0;

    case (prep_cnt)
        4'd0:  begin det_a = mat[0];  det_b = mat[1];  det_c = mat[4];  det_d = mat[5];  end
        4'd1:  begin det_a = mat[1];  det_b = mat[2];  det_c = mat[5];  det_d = mat[6];  end
        4'd2:  begin det_a = mat[2];  det_b = mat[3];  det_c = mat[6];  det_d = mat[7];  end
        4'd3:  begin det_a = mat[4];  det_b = mat[5];  det_c = mat[8];  det_d = mat[9];  end
        4'd4:  begin det_a = mat[5];  det_b = mat[6];  det_c = mat[9];  det_d = mat[10]; end
        4'd5:  begin det_a = mat[6];  det_b = mat[7];  det_c = mat[10]; det_d = mat[11]; end
        4'd6:  begin det_a = mat[8];  det_b = mat[9];  det_c = mat[12]; det_d = mat[13]; end
        4'd7:  begin det_a = mat[9];  det_b = mat[10]; det_c = mat[13]; det_d = mat[14]; end
        4'd8:  begin det_a = mat[10]; det_b = mat[11]; det_c = mat[14]; det_d = mat[15]; end

        4'd9:  begin det_a = mat[4];  det_b = mat[6];  det_c = mat[8];  det_d = mat[10]; end
        4'd10: begin det_a = mat[5];  det_b = mat[7];  det_c = mat[9];  det_d = mat[11]; end
        4'd11: begin det_a = mat[8];  det_b = mat[10]; det_c = mat[12]; det_d = mat[14]; end
        4'd12: begin det_a = mat[9];  det_b = mat[11]; det_c = mat[13]; det_d = mat[15]; end

        4'd13: begin det_a = mat[8];  det_b = mat[11]; det_c = mat[12]; det_d = mat[15]; end

        default: begin det_a = 11'sd0; det_b = 11'sd0; det_c = 11'sd0; det_d = 11'sd0; end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 9; i = i + 1)
            m2[i] <= 23'sd0;

        for (i = 0; i < 4; i = i + 1)
            sp[i] <= 23'sd0;

        x03 <= 23'sd0;
    end
    else if (c_s == PREP2) begin
        if (prep_cnt <= 4'd8)
            m2[prep_cnt] <= det_out;
        else if (prep_cnt <= 4'd12)
            sp[prep_cnt - 4'd9] <= det_out;
        else if (prep_cnt == 4'd13)
            x03 <= det_out;
    end
end

//=====================================================
// Shared 3x3 datapath
// det3 = c0*m0 - c1*m1 + c2*m2
//=====================================================
reg signed [10:0] c0_3;
reg signed [10:0] c1_3;
reg signed [10:0] c2_3;

reg signed [22:0] m0_3;
reg signed [22:0] m1_3;
reg signed [22:0] m2_3;

wire signed [33:0] p0_3;
wire signed [33:0] p1_3;
wire signed [33:0] p2_3;

wire signed [34:0] p0_3_ext;
wire signed [34:0] p1_3_ext;
wire signed [34:0] p2_3_ext;

wire signed [34:0] det3_val;

assign p0_3 = c0_3 * m0_3;
assign p1_3 = c1_3 * m1_3;
assign p2_3 = c2_3 * m2_3;

assign p0_3_ext = {p0_3[33], p0_3};
assign p1_3_ext = {p1_3[33], p1_3};
assign p2_3_ext = {p2_3[33], p2_3};

assign det3_val = p0_3_ext - p1_3_ext + p2_3_ext;

always @(*) begin
    c0_3 = 11'sd0;
    c1_3 = 11'sd0;
    c2_3 = 11'sd0;

    m0_3 = 23'sd0;
    m1_3 = 23'sd0;
    m2_3 = 23'sd0;

    if (mode_3x3) begin
        case (calc3_cnt)
            3'd0: begin
                c0_3 = mat[0]; c1_3 = mat[1]; c2_3 = mat[2];
                m0_3 = m2[4];  m1_3 = sp[0];  m2_3 = m2[3];
            end

            3'd1: begin
                c0_3 = mat[1]; c1_3 = mat[2]; c2_3 = mat[3];
                m0_3 = m2[5];  m1_3 = sp[1];  m2_3 = m2[4];
            end

            3'd2: begin
                c0_3 = mat[4]; c1_3 = mat[5]; c2_3 = mat[6];
                m0_3 = m2[7];  m1_3 = sp[2];  m2_3 = m2[6];
            end

            3'd3: begin
                c0_3 = mat[5]; c1_3 = mat[6]; c2_3 = mat[7];
                m0_3 = m2[8];  m1_3 = sp[3];  m2_3 = m2[7];
            end

            default: begin
                c0_3 = 11'sd0; c1_3 = 11'sd0; c2_3 = 11'sd0;
                m0_3 = 23'sd0; m1_3 = 23'sd0; m2_3 = 23'sd0;
            end
        endcase
    end
    else if (mode_4x4) begin
        case (calc3_cnt)
            3'd0: begin
                c0_3 = mat[5]; c1_3 = mat[6]; c2_3 = mat[7];
                m0_3 = m2[8];  m1_3 = sp[3];  m2_3 = m2[7];
            end

            3'd1: begin
                c0_3 = mat[4]; c1_3 = mat[6]; c2_3 = mat[7];
                m0_3 = m2[8];  m1_3 = x03;    m2_3 = sp[2];
            end

            3'd2: begin
                c0_3 = mat[4]; c1_3 = mat[5]; c2_3 = mat[7];
                m0_3 = sp[3];  m1_3 = x03;    m2_3 = m2[6];
            end

            3'd3: begin
                c0_3 = mat[4]; c1_3 = mat[5]; c2_3 = mat[6];
                m0_3 = m2[7];  m1_3 = sp[2];  m2_3 = m2[6];
            end

            default: begin
                c0_3 = 11'sd0; c1_3 = 11'sd0; c2_3 = 11'sd0;
                m0_3 = 23'sd0; m1_3 = 23'sd0; m2_3 = 23'sd0;
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1) begin
            r3[i]  <= 35'sd0;
            cof[i] <= 35'sd0;
        end
    end
    else if (c_s == CALC3) begin
        if (mode_3x3)
            r3[calc3_cnt] <= det3_val;
        else if (mode_4x4)
            cof[calc3_cnt] <= det3_val;
    end
end

//=====================================================
// 4x4 accumulator
// det4 = mat0*cof0 - mat1*cof1 + mat2*cof2 - mat3*cof3
//=====================================================
reg signed [10:0] c4;
reg signed [34:0] m4;

wire signed [45:0] p4;
wire signed [47:0] p4_ext;
wire signed [47:0] acc4_next;

assign p4 = c4 * m4;
assign p4_ext = {{2{p4[45]}}, p4};

assign acc4_next = (calc4_cnt == 3'd0) ? p4_ext :
                   (calc4_cnt == 3'd1) ? acc4 - p4_ext :
                   (calc4_cnt == 3'd2) ? acc4 + p4_ext :
                                          acc4 - p4_ext;

always @(*) begin
    c4 = 11'sd0;
    m4 = 35'sd0;

    case (calc4_cnt)
        3'd0: begin c4 = mat[0]; m4 = cof[0]; end
        3'd1: begin c4 = mat[1]; m4 = cof[1]; end
        3'd2: begin c4 = mat[2]; m4 = cof[2]; end
        3'd3: begin c4 = mat[3]; m4 = cof[3]; end
        default: begin c4 = 11'sd0; m4 = 35'sd0; end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        acc4 <= 48'sd0;
        result4 <= 48'sd0;
    end
    else if (c_s == CALC4) begin
        acc4 <= acc4_next;

        if (calc4_cnt == 3'd3)
            result4 <= acc4_next;
    end
    else if (c_s == IDLE) begin
        acc4 <= 48'sd0;
        result4 <= 48'sd0;
    end
end

//=====================================================
// Output
//=====================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
        out_data  <= 207'd0;
    end
    else begin
        if (c_s == OUT) begin
            out_valid <= 1'b1;

            if (mode_2x2) begin
                out_data <= {
                    m2[0], m2[1], m2[2],
                    m2[3], m2[4], m2[5],
                    m2[6], m2[7], m2[8]
                };
            end
            else if (mode_3x3) begin
                out_data <= {
                    3'b000,
                    {{16{r3[0][34]}}, r3[0]},
                    {{16{r3[1][34]}}, r3[1]},
                    {{16{r3[2][34]}}, r3[2]},
                    {{16{r3[3][34]}}, r3[3]}
                };
            end
            else if (mode_4x4) begin
                out_data <= {{159{result4[47]}}, result4};
            end
            else begin
                out_data <= 207'd0;
            end
        end
        else begin
            out_valid <= 1'b0;
            out_data  <= 207'd0;
        end
    end
end

endmodule


module DET (
    in1,
    in2,
    in3,
    in4,
    out
);

input signed [10:0] in1;
input signed [10:0] in2;
input signed [10:0] in3;
input signed [10:0] in4;

output signed [22:0] out;

wire signed [21:0] mul1;
wire signed [21:0] mul2;

assign mul1 = in1 * in2;
assign mul2 = in3 * in4;

assign out = {mul1[21], mul1} - {mul2[21], mul2};

endmodule