class scoreboard;

    mailbox #(conv_transaction) drv2scb;
    mailbox #(conv_transaction) mon2scb;

    int unsigned target_num;
    int unsigned checked_num;
    int unsigned pass_num;
    int unsigned fail_num;

    bit done;

    function new(
        mailbox#(conv_transaction)drv2scb,
        mailbox#(conv_transaction)mon2scb,
        int unsigned target_num
    );
    this.drv2scb = drv2scb;
    this.mon2scb = mon2scb;
    this.target_num = target_num;

    this.checked_num = 0;
    this.pass_num = 0;
    this.fail_num = 0;
    this.done = 0;
    endfunction

    task run();
        conv_transaction expected_tr;
        conv_transaction actual_tr;

        forever begin
            drv2scb.get(expected_tr);

            mon2scb.get(actual_tr);

            checked_num = checked_num +1;

            if(actual_tr.actual !== expected_tr.expected) begin
                fail_num = fail_num + 1;
            
                $display("================================================");
                $display("[SCB] FAIL");
                $display("Pattern ID : %0d", expected_tr.id);
                $display("Expected   : %0d", expected_tr.expected);
                $display("Actual     : %0d", actual_tr.actual);
                $display("Time       : %0t", $time);
                $display("================================================");
            end
            else begin
                pass_num = pass_num + 1;

                // 前三筆確認流程正確
                if(checked_num <= 3) begin
                    $display("[SCB] PASS  %0d/%0d | id=%0d | answer=%0d",
                             checked_num,
                             target_num,
                             expected_tr.id,
                             actual_tr.actual);
                end

                // 每 1000 筆印一次進度
                else if((checked_num % 1000) == 0) begin
                    $display("[SCB] Progress: %0d/%0d | PASS=%0d | FAIL=%0d",
                             checked_num,
                             target_num,
                             pass_num,
                             fail_num);
                end

                // 最後一筆
                else if(checked_num == target_num) begin
                    $display("[SCB] PASS  %0d/%0d | id=%0d | answer=%0d",
                             checked_num,
                             target_num,
                             expected_tr.id,
                             actual_tr.actual);
                end
            end

            if(checked_num == target_num) begin

                $display("================================================");
                $display("[SCOREBOARD] Verification finished");
                $display("Total checked : %0d", checked_num);
                $display("PASS          : %0d", pass_num);
                $display("FAIL          : %0d", fail_num);
                $display("================================================");

                done = 1'b1;

                return;
            end


        end
    endtask


endclass