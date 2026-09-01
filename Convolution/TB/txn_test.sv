`timescale 1ns/1ps

`include "../TB/conv_transaction.sv"

module txn_test;

    conv_transaction tr;

    initial begin
        tr = new();

        assert(tr.randomize())
        else begin
            $display("Randomize failed.");
            $finish;
        end

        tr.calc_expected();
        tr.display("FIRST RANDOM PATTERN");

        $finish;
    end

endmodule