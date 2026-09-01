class conv_transaction;
rand bit [3:0] ifm [1:32];
rand bit [3:0] weight [1:32];

bit [12:0] expected;
logic [12:0]actual;

int unsigned id;

function void calc_expected();
    int unsigned sum;

    sum = 0;

    for (int i = 0; i<=32; i++)begin
        sum += ifm[i] * weight[i];   
    end

    expected = sum[12:0];
endfunction

function void display(string tag = "TRANSACTION");
    $display("[%s] id = %0d, expected = %0d, actual = %0d", tag, id, expected, actual);
endfunction

endclass