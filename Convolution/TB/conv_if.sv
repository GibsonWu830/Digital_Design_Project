interface conv_if(input logic clk);
    
    //RESET
    logic rst_n;
    
    //Input control
    logic in_valid;
    logic weight_valid;
    logic in_ready;

    logic [3:0]ifm [1:32];
    logic [3:0]weight [1:32];

    logic out_valid;
    logic [12:0]Out_OFM;
    

    modport DRV (
        input clk,
        input in_ready,
        output rst_n,
        output in_valid,
        output weight_valid,
        output ifm,
        output weight
    );

    modport MON (
        input clk,
        input rst_n,
        input in_valid,
        input weight_valid,
        input in_ready,
        input ifm,
        input weight,

        input out_valid,
        input Out_OFM
    );

endinterface