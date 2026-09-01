class monitor;

virtual conv_if.MON vif;

mailbox #(conv_transaction) mon2scb;


function new(
    virtual conv_if.MON vif,
    mailbox #(conv_transaction) mon2scb
);
this.vif = vif;
this.mon2scb = mon2scb;
endfunction


task run();
    conv_transaction tr;

    forever begin
        @(negedge vif.clk);
        if(vif.out_valid ===1'b1)begin
            tr = new();

            tr.actual = vif.Out_OFM;

            mon2scb.put(tr);
        end
    end
endtask

endclass