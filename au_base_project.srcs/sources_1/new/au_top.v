module au_top(
    input clk,
    input rst_n,
    output[7:0] led,
    input usb_rx,
    output usb_tx,
    
    output advk_sda_out,
    input advk_scl,
    input advk_sda_in,
    
    output temp_sda_out,
    output temp_scl,
    input temp_sda_in 
    );
    
    wire rst;
    
    reset_conditioner reset_conditioner(.clk(clk), .in(!rst_n), .out(rst));
       
    //assign led = rst ? 8'hAA : 8'h55;    
    //assign usb_tx = usb_rx;
    
    wire[7:0] data_byte;
    wire tx_done,tx_active,rx_done;
       
    assign advk_sda_out=temp_sda_in;
    assign temp_scl = advk_scl;
    assign temp_sda_out = advk_sda_in;
    
   // message_rom message_rom_hw(clk,byte_address,tx_byte);
        
    uart_rx uart_rx_reciever(clk,usb_rx,rx_done,data_byte);
    uart_tx uart_tx_transmitter(clk,rx_done,data_byte,tx_active,usb_tx,tx_done);
       
    assign led[6:0] = data_byte[6:0];
    assign led[7] = advk_scl;
    
    
endmodule
