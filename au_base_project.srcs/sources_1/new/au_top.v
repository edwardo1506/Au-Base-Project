module au_top(
    input clk,
    input rst_n,
    output[7:0] led,
    input usb_rx,
    output usb_tx,
    input advk_scl,
    output temp_scl,
    input advk_sda_in,
    output advk_sda_out,
    input temp_sda_in,
    output temp_sda_out
    );
    
    wire rst;
    
    reset_conditioner reset_conditioner(.clk(clk), .in(!rst_n), .out(rst));
       
    assign led = rst ? 8'hAA : 8'h55;    
    assign usb_tx = usb_rx;
    
    assign temp_sda_out = advk_sda_in;
    assign advk_sda_out = temp_sda_in;    
    assign temp_scl = advk_scl;    
        
        
endmodule
