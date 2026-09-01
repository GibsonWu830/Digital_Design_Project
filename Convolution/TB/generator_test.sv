`timescal 1ns/1ps

`include "../TB/conv_transaction.sv"
`include "../TB/generator.sv"

module generator ();
    
    parameter PAT_NUM = 9999;

    mailbox#(conv_transaction) gen2drv;

    generator gen;
    conv_transaction tr;

    initial begin
        
        gen2drv = new();

        gen = new(gen2drv,PAT_NUM);
        fork
            // Generator 不斷產生 transaction
            gen.run();

            // 暫時扮演未來的 Driver
            begin
                repeat(PAT_NUM) begin
                    gen2drv.get(tr);
                    tr.display("RECEIVER");
                end
            end

        join
        $display("================================================");
        $display("       Generator / Mailbox Test PASS");
        $display("================================================");
        $finish;
    end
endmodule