//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.08.2020 21:18:03
// Design Name: 
// Module Name: i2c_state_parser
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_state_parser(
    input rst,
    input clk,
    input i2c_scl,
    input i2c_sda,
    output debug0,
    output debug1,
    output debug2,
    output who_has_sda_out,
    output[3:0] bit_counter
    );
    
    localparam SAMPLE_BIT = 2;
    reg[3:0] synced_scl = 3'b0000;
    reg[3:0] synced_sda = 3'b0000;
    
    reg  scl_rising_edge = 0;
    reg  scl_falling_edge = 0;
    reg  sda_rising_edge = 0;
    reg  sda_falling_edge = 0;
    
    
    reg rw = 0; // 0 is master writing!
    reg who_has_sda = 0; // 0 is master has sda
    reg master_ack_nack = 0; // 0 is ack
    reg[31:0] timeout_counter = 32'd0;
    
    // waiting for START condition
    parameter STATE_IDLE = 3'd0;    
    // address+wr transaction
    parameter STATE_MASTER_ADDRESS_WR = 3'd1;
    parameter STATE_SLAVE_START_ACKNACK = 3'd2;
    // write byte + acknack transaction
    parameter STATE_MASTER_WRITE_BYTE = 3'd3;
    parameter STATE_MASTER_WRITE_SLAVE_ACKNACK = 3'd4;
    // read byte + acknack
    parameter STATE_MASTER_READ_BYTE = 3'd5;    
    parameter STATE_MASTER_READ_MASTER_ACKNACK = 3'd6;

    reg[2:0] state = STATE_IDLE;
        
    reg[3:0] r_bit_counter = 4'b0000;    
    reg[6:0] address = 7'b0000000;
        
       
    always @(*) begin
        // blocking! - name assignment for easy reading
        scl_rising_edge =  (~synced_scl[SAMPLE_BIT + 1] & synced_scl[SAMPLE_BIT]);
        scl_falling_edge = (synced_scl[SAMPLE_BIT + 1] & ~synced_scl[SAMPLE_BIT]);
        sda_rising_edge =  (~synced_sda[SAMPLE_BIT + 1] & synced_sda[SAMPLE_BIT]);
        sda_falling_edge = (synced_sda[SAMPLE_BIT + 1] & ~synced_sda[SAMPLE_BIT]);
    end    
        
    always @(posedge clk) begin
        synced_scl <= { synced_scl[2:0] , i2c_scl };
        synced_sda <= { synced_sda[2:0] , i2c_sda };
    end
    
    always @(posedge clk) begin
            case(state) 
            STATE_IDLE: begin
                // this detects the start condition!
                if ( sda_falling_edge && synced_scl[SAMPLE_BIT] ) 
                    state <= STATE_MASTER_ADDRESS_WR;
                else
                    state <= STATE_IDLE;
                who_has_sda <= 1'b0; // MASTER has sda
                r_bit_counter <= 4'b0000;
                address <= 7'b0000000;
                rw <= 1'b0;   
                master_ack_nack <= 1'b0;
            end
            
            /// ############## MASTER ADDRESS+W/R SUB-STATES ###################### ///
            
            STATE_MASTER_ADDRESS_WR: begin
                // here we read the 7-bit address and the w/r bit (MSB first) into a local register on scl rising edges
                if ( scl_rising_edge && (r_bit_counter <= 6) ) begin
                    address[6-r_bit_counter] <= synced_sda[SAMPLE_BIT];
                    r_bit_counter <= r_bit_counter + 1;
                    who_has_sda <= 1'b0; // MASTER has sda
                end else if ( scl_rising_edge && (r_bit_counter == 7)) begin
                    rw <= synced_sda[SAMPLE_BIT];
                    r_bit_counter <= r_bit_counter + 1;
                    who_has_sda <= 1'b0; // MASTER has sda                                                            
                end else if (scl_falling_edge && (r_bit_counter == 8)) begin
                    who_has_sda <= 1'b1; // SLAVE has sda for ACK/NACK setup
                    r_bit_counter <= 4'b0000; 
                    state <= STATE_SLAVE_START_ACKNACK; 
                end else
                    state <= STATE_MASTER_ADDRESS_WR;
    
            end        
            STATE_SLAVE_START_ACKNACK: begin
                 // ACK/NACK pulse started
                 if(scl_rising_edge && (r_bit_counter == 0) ) begin
                    who_has_sda <= 1'b1; // SLAVE has sda
                    r_bit_counter <= r_bit_counter + 1;
                 end
                 // ACK/NACK pulse is over -> go back to sda master control and move on
                 else if (scl_falling_edge && (r_bit_counter == 1)) begin                    
                    r_bit_counter <= 4'b0000;
                    state <=  rw ? STATE_MASTER_READ_BYTE : STATE_MASTER_WRITE_BYTE;
                    who_has_sda <= rw; // MASTER has sda if write or SLAVE if READ
                 end else
                    state <= STATE_SLAVE_START_ACKNACK;
                 
            end
            
           /// ############## MASTER WRITE SUB-STATES ###################### ///
            
            
            STATE_MASTER_WRITE_BYTE: begin
                // here we count the 8-bit data (MSB first) and move along
                if ( scl_rising_edge && (r_bit_counter <= 7) ) begin                    
                    r_bit_counter <= r_bit_counter + 1;
                    who_has_sda <= 1'b0; // MASTER has sda
                end
                else if (scl_falling_edge && (r_bit_counter == 8)) begin
                    who_has_sda <= 1'b1; // SLAVE has sda for ACK/NACK setup
                    r_bit_counter <= 4'b0000; 
                    state <= STATE_MASTER_WRITE_SLAVE_ACKNACK; 
                end else
                    state <= STATE_MASTER_WRITE_BYTE; 
            end
            STATE_MASTER_WRITE_SLAVE_ACKNACK: begin
                 
                 // ACK/NACK pulse started
                 if(scl_rising_edge && (r_bit_counter == 0) ) begin
                    who_has_sda <= 1'b1; // SLAVE has sda
                    r_bit_counter <= r_bit_counter + 1;
                 end
                 // ACK/NACK pulse is over -> go back to sda master control and move on
                 else if (scl_falling_edge && (r_bit_counter == 1)) begin                    
                    r_bit_counter <= 4'b0000;
                    state <=  STATE_MASTER_WRITE_BYTE;
                    who_has_sda <= 0; // MASTER has sda to write another byte or stop condition
                 end else
                    state <= STATE_MASTER_WRITE_SLAVE_ACKNACK;
            end
            
            /// ############## MASTER READ SUB-STATES ###################### ///
            
            STATE_MASTER_READ_BYTE: begin
                // here we count the 8-bit data (MSB first) and move along
                if ( scl_rising_edge && (r_bit_counter <= 7) ) begin                    
                    r_bit_counter <= r_bit_counter + 1;
                    who_has_sda <= 1'b1; // SLAVE has sda
                end
                else if (scl_falling_edge && (r_bit_counter == 8)) begin
                    who_has_sda <= 1'b0; // MASTER has sda for ACK/NACK setup
                    r_bit_counter <= 4'b0000; 
                    state <= STATE_MASTER_READ_MASTER_ACKNACK; 
                end else 
                    state <= STATE_MASTER_READ_BYTE;                 
            end
            STATE_MASTER_READ_MASTER_ACKNACK: begin
                 // ACK/NACK pulse started
                 if(scl_rising_edge && (r_bit_counter == 0) ) begin
                    who_has_sda <= 1'b0; // MASTER has sda
                    r_bit_counter <= r_bit_counter + 1;
                    master_ack_nack <= synced_sda[SAMPLE_BIT];
                 end
                 // ACK/NACK pulse is over -> go back to sda master control and move on
                 else if (scl_falling_edge && (r_bit_counter == 1)) begin                                                          
                    r_bit_counter <= 4'b0000;
                    // master sent ACK so we give sda to slave and read another byte
                    if (~master_ack_nack) begin
                        state <=  STATE_MASTER_READ_BYTE;  
                        who_has_sda <= 1'b1; // give sda back to SLAVE after MASTER-ACK                        
                    // master sent NACK so we expect to see a STOP condition -> give sda back to master
                    end else begin
                        who_has_sda <= 1'b0; // give sda back to MASTER after MASTER-NACK
                        state <= STATE_IDLE; // go to waiting pattern? for now just go to idle? :S
                    end                    
                 end else
                    state <= STATE_MASTER_READ_MASTER_ACKNACK;            
            end
                
            endcase
          
          // stop condition detected -> go to IDLE
          if(sda_rising_edge && synced_scl[SAMPLE_BIT]) begin            
            who_has_sda <= 1'b0; // MASTER has sda
            r_bit_counter <= 4'b0000;
            address <= 7'b0000000;
            rw <= 1'b0;   
            master_ack_nack <= 1'b0;
            state <= STATE_IDLE;
          end
          // start detected go back to STATE_MASTER_ADDRESS_WR
          if(sda_falling_edge && synced_scl[SAMPLE_BIT]) begin
            // go back to STATE_MASTER_ADDRESS_WR
            who_has_sda <= 1'b0; // MASTER has sda
            r_bit_counter <= 4'b0000;
            address <= 7'b0000000;
            rw <= 1'b0;   
            master_ack_nack <= 1'b0;
            state <= STATE_MASTER_ADDRESS_WR;
          end
    
        
    end

    
    assign debug0 = state[0];
    assign debug1 = state[1];
    assign debug2 = state[2];
    assign who_has_sda_out = who_has_sda;
    assign bit_counter = r_bit_counter;
endmodule