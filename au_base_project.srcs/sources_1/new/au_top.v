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
    input temp_sda_in, 
    
    output [3:0] bit_counter
    );
    
    wire rst;
    
    reset_conditioner reset_conditioner(.clk(clk), .in(!rst_n), .out(rst));
       
    //assign led = rst ? 8'hAA : 8'h55;    
    //assign usb_tx = usb_rx;
    
    wire[7:0] data_byte;
    wire tx_done,tx_active,rx_done;
    wire debug0,debug1,debug2;
    wire who_has_sda_out;
    wire master_has_sda, slave_has_sda;
    reg r_temp_sda_out = 1;
    reg r_advk_sda_out = 1;
    
    i2c_state_parser state_parser(rst,clk,advk_scl,advk_sda_in,debug0,debug1,debug2,who_has_sda_out,bit_counter[3:0]);     
       
    // clock goes as-is
    assign temp_scl = advk_scl;
    
    who_has_sda_box sda_box(clk,who_has_sda_out,master_has_sda,slave_has_sda);        
    
    always @(*) begin
        r_temp_sda_out = master_has_sda ?  advk_sda_in : 1'b1; 
        r_advk_sda_out = slave_has_sda  ?  temp_sda_in : 1'b1;      
    end
    
    assign advk_sda_out = r_advk_sda_out;    
    assign temp_sda_out = r_temp_sda_out;
    
   // message_rom message_rom_hw(clk,byte_address,tx_byte);
        
    uart_rx uart_rx_reciever(clk,usb_rx,rx_done,data_byte);
    uart_tx uart_tx_transmitter(clk,rx_done,data_byte,tx_active,usb_tx,tx_done);
       
    assign led[3:0] = bit_counter[3:0];
    assign led[7] = advk_scl;
    
    
endmodule
