module apb_slave #(
    width_addr = 8,
    width_data = 32,
    depth_rrmem = 256)
(
    input                           rst_n, 
    input                           clk,     // PCLK
    input                           select,  // PSEL
    input                           wr_ena,  // PWRITE // W/R state data (rd=0, wr=1)
    input                           en_vld,  // PENABLE // W/R state transition enable
  	input        [width_addr-1:0]   addr,    // PADDR
  	input        [width_data-1:0]   wr_data, // PWDATA
  	output logic [width_data-1:0]   rd_data  // PRDATA
);

    // local resources
    logic [width_data-1:0] rmem [depth_rrmem]; // register-based memory

    // FSM states
    logic 			[2:0] next_state;
    const logic 	[2:0] IDLE  = 3'b001;
    const logic 	[2:0] WRITE = 3'b010;
    const logic 	[2:0] READ  = 3'b100;

    always @ (negedge rst_n or posedge clk) begin : APB_FSM
        if (rst_n == 0) begin
            next_state <= IDLE;
            rd_data <= 0;
        end else begin    
            case (next_state)
                IDLE : begin        
                    rd_data <= 0;
                  	if (select && wr_ena) // flat logic structure 
                  		next_state <= WRITE;                 
	                if (select && !wr_ena)              	
                  		next_state <= READ;
                end              
                WRITE : begin        
	                if (select && wr_ena && en_vld) begin // sample on en_vld (PENABLE)
                        rmem[addr] <= wr_data; 
                    end        
                    next_state <= IDLE;
                end
                READ : begin        
                    if (select && !wr_ena && en_vld) begin 
                        rd_data <= rmem[addr]; 
                    end        
                    next_state <= IDLE;
                end             
            endcase    
        end
    end 

endmodule