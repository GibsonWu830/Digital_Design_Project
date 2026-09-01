class generator;

    mailbox #(conv_transaction) gen2drv;

    int pattern_num;

    function new(
        mailbox #(conv_transaction) gen2drv,
        int pattern_num = 10
    );
        this.gen2drv    = gen2drv;
        this.pattern_num = pattern_num;
    endfunction

    task run();

        conv_transaction tr;

        for(int pat = 0; pat < pattern_num; pat = pat + 1) begin

            tr = new();

            assert(tr.randomize())
            else begin
                $display("[GENERATOR] randomize failed.");
                $finish;
            end

            tr.id = pat;
            tr.calc_expected();

            gen2drv.put(tr);

            // tr.display("GENERATOR");
        end

    endtask

endclass