`timescale 1ns/1ps

module can_bit_stuffing (
  input  logic clk,
  input  logic rst_n,
  
  input  logic enable,      // Enable stuffing
  input  logic data_in,     // Data from TX FSM
  input  logic tx_point,    // Bit timing
  
  output logic data_out,    // Stuffed data to bus
  output logic stuff_stall  // Stall TX FSM when stuff bit inserted
);

  logic [2:0] consec_bits;
  logic last_bit;
  logic insert_stuff;
  
  always_comb begin
    insert_stuff = (consec_bits == 3'd4) && enable && (data_in == last_bit);
    stuff_stall = insert_stuff;
    
    if (insert_stuff) data_out = ~last_bit; // Insert opposite bit
    else data_out = data_in;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      consec_bits <= 3'd0;
      last_bit <= 1'b1; // Bus idle is recessive
    end else if (tx_point && enable) begin
      if (insert_stuff) begin
        // Inserted stuff bit, reset counter to 1 (counting the stuff bit itself)
        consec_bits <= 3'd1;
        last_bit <= ~last_bit;
      end else begin
        last_bit <= data_in;
        if (data_in == last_bit) begin
          consec_bits <= consec_bits + 1'b1;
        end else begin
          consec_bits <= 3'd1;
        end
      end
    end else if (!enable) begin
      consec_bits <= 3'd0;
      last_bit <= 1'b1;
    end
  end

endmodule
