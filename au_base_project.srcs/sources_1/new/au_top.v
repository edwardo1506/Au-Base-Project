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
    
    wire[7:0] serial_data_byte;
    wire[7:0] i2c_data_byte;
    
    wire tx_done,tx_active,rx_done;
    wire covert_sda_control;
    wire who_has_sda_out;
    wire master_has_sda, slave_has_sda;
    wire i2c_slave_sda_out;
    reg r_temp_sda_out = 1;
    reg r_advk_sda_out = 1;
    reg r_advk_sda_out_from_temp = 1;
    wire data_read_flag;
    wire[1:0] dummy_wire;
    
    i2c_state_parser state_parser(rst,clk,advk_scl,advk_sda_in,covert_sda_control,who_has_sda_out, {bit_counter[3:2],dummy_wire[1:0]});     
    i2c_slave i2c_slave(rst,clk,advk_scl,advk_sda_in,i2c_slave_sda_out,i2c_data_byte,data_read_flag,0);    
    
    // clock goes as-is
    assign temp_scl = advk_scl;
    
    who_has_sda_box sda_box(clk,who_has_sda_out,master_has_sda,slave_has_sda);        
    
    always @(*) begin
        r_temp_sda_out          = master_has_sda ?  advk_sda_in : 1'b1; 
        r_advk_sda_out_from_temp =  slave_has_sda  ?  temp_sda_in : 1'b1; 
        r_advk_sda_out  = covert_sda_control ? i2c_slave_sda_out : r_advk_sda_out_from_temp;     
    end
    
    assign advk_sda_out = r_advk_sda_out;    
    assign temp_sda_out = r_temp_sda_out;
    
   // message_rom message_rom_hw(clk,byte_address,tx_byte);
        
    uart_rx uart_rx_reciever(clk,usb_rx,rx_done,serial_data_byte);
    uart_tx uart_tx_transmitter(clk,data_read_flag,i2c_data_byte,tx_active,usb_tx,tx_done);
       
    assign led[7:0] = i2c_data_byte[7:0];    
    assign bit_counter[1:0] = { data_read_flag, i2c_slave_sda_out};
    
endmodule
