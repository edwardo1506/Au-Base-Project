//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.08.2020 11:26:19
// Design Name: 
// Module Name: who_has_sda_box
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


module who_has_sda_box(
    input clk,
    input who_has_sda,
    output master_has,
    output slave_has
    );
    
    reg r_master_has = 1'b1;
    reg r_slave_has = 1'b0;
    
    localparam STATE_MASTER_HAS = 1'b0;
    localparam STATE_SLAVE_HAS  = 1'b1;
        
    reg r_state = STATE_MASTER_HAS; 
    reg[3:0] counter = 4'b0000;
    
    always @(posedge clk) begin
        case(r_state)
            STATE_MASTER_HAS: begin
                if (who_has_sda) begin
                    if (counter < 15) begin
                        r_slave_has <= 1'b1;
                        r_master_has <= 1'b1;
                        counter <= counter + 1;
                    end else begin
                        r_slave_has <= 1'b1;
                        r_master_has <= 1'b0;
                        counter <= 4'b0000;
                        r_state <= STATE_SLAVE_HAS;                        
                    end
                end else begin
                    r_state <= STATE_MASTER_HAS;
                    counter <= 4'b0000;
                end               
            end
            STATE_SLAVE_HAS: begin
                if (~who_has_sda) begin
                    if (counter < 15) begin
                        r_slave_has <= 1'b1;
                        r_master_has <= 1'b1;
                        counter <= counter + 1;
                    end else begin
                        r_slave_has <= 1'b0;
                        r_master_has <= 1'b1;
                        counter <= 4'b0000;
                        r_state <= STATE_MASTER_HAS;                        
                    end
                end else begin
                    r_state <= STATE_SLAVE_HAS;
                    counter <= 4'b0000;
                end                        
            end
        endcase
        
    end
    
    assign master_has = r_master_has;
    assign slave_has  = r_slave_has;
    
endmodule
