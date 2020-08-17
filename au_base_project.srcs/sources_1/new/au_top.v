module au_top(
    input clk,
    input rst_n,
    output[7:0] led,
    input usb_rx,
    output usb_tx
    );
    
    wire rst;
    
    reset_conditioner reset_conditioner(.clk(clk), .in(!rst_n), .out(rst));
       
    //assign led = rst ? 8'hAA : 8'h55;    
    //assign usb_tx = usb_rx;
    
    parameter s_IDLE  = 2'b00;
    parameter s_PRINTING   = 2'b01;
    parameter s_DONE  = 2'b10;
   
    reg[3:0] byte_address = 4'h0;
    wire[7:0] tx_byte;
    wire tx_done,tx_active;
    reg[1:0] state = s_IDLE;
    reg tx_start = 1'b0;
    reg tx_start_counter = 1'b0;
    
    message_rom message_rom_hw(clk,byte_address,tx_byte);
       
    uart_tx uart_tx_transmitter(clk,tx_start,tx_byte,tx_active,usb_tx,tx_done);
    
    always @(posedge clk) begin
        case (state)
        s_IDLE: begin
            tx_start <= 1'b0;
            tx_start_counter = 1'b0;
            state <= s_PRINTING;
        end
        s_PRINTING: begin            
            if (~tx_start_counter) begin
                tx_start <= 1'b1;
                tx_start_counter <= 1'b1; 
            end else
                tx_start <= 1'b0;
                
            tx_start_counter <= 1'b1;                                                                            
            if (tx_done /* && !tx_active */ ) begin 
                byte_address <= byte_address + 1;
                tx_start_counter <= 1'b0;        
            end
            if (byte_address > 4'd12)
                state <= s_DONE;
        end
        s_DONE: begin
            tx_start <= 1'b0;
            tx_start_counter = 1'b0;
            state <= s_DONE;            
        end
        //default: state <= s_IDLE;
        endcase
        
        if(rst) begin
            tx_start <= 1'b0;
            byte_address <= 4'h0;
            state <= s_IDLE;              
        end
    end       
    
    assign led[1:0] = state[1:0];    
    assign led[2] = tx_done;
    assign led[3] = tx_start;
    assign led[7:4] = byte_address;
    
    
endmodule
