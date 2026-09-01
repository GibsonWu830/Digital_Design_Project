class driver;
    virtual conv_if.DRV vif;
    mailbox #(conv_transaction) gen2drv;
    mailbox #(conv_transaction) drv2scb;
    
    function new(
        virtual conv_if.DRV vif,
        mailbox #(conv_transaction) gen2drv,
        mailbox #(conv_transaction) drv2scb
    );
    this.vif = vif;
    this.gen2drv = gen2drv;
    this.drv2scb = drv2scb;
    endfunction
    // ----------------------------------------
    // Reset DUT
    // ----------------------------------------
    task reset_dut();
        vif.rst_n = 1'b0;
        vif.in_valid = 1'b0;
        vif.weight_valid = 1'b0;

        for (int i = 1 ; i <=32; i++)begin
            vif.ifm[i] = 4'b0;
            vif.weight[i] = 4'b0;
        end
        repeat(2) @(negedge vif.clk);
        vif.rst_n = 1'b1;

        @(negedge vif.clk);
        $display("[DRIVER] Reset complete.");        

    endtask

    task send_transaction(conv_transaction tr);
        @(negedge vif.clk);

        while (vif.in_ready !== 1'b1)begin
            @(negedge vif.clk);
        end

        for (int i = 1; i <= 32; i++)begin
            vif.ifm[i] = tr.ifm[i];
            vif.weight[i] = tr.weight[i];
        end

        vif.in_valid = 1'b1;
        vif.weight_valid = 1'b1;

        // $display("[DRIVER] Drive id = %0d, expected = %0d",tr.id,tr.expected);
        do begin
            @(posedge vif.clk);
        end while(vif.in_ready !== 1'b1);

        drv2scb.put(tr);

        @(negedge vif.clk);

        vif.in_valid = 1'b0;
        vif.weight_valid = 1'b0;

        for(int i = 1; i<=32; i++)begin
            vif.ifm[i] = 'x;
            vif.weight[i] = 'x;
        end
    endtask

    task run();
        conv_transaction tr;

        reset_dut();

        forever begin
            gen2drv.get(tr);
            send_transaction(tr);
        end
    endtask



endclass