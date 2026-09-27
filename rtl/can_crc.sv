`timescale 1ns/1ps

module can_crc (
  input  logic clk,
  input  logic rst_n,
  
  input  logic enable,      // Calculate CRC
  input  logic data_in,     // Serial data input
  input  logic clear,       // Clear CRC register
  
  output logic [14:0] crc_out
);

  // CAN CRC polynomial: x^15 + x^14 + x^10 + x^8 + x^7 + x^4 + x^3 + 1
  // 1100010110011001 -> 15'h4599
  
  logic [14:0] crc_nxt;
  logic crc_next_bit;

  assign crc_next_bit = data_in ^ crc_out[14];
  
  always_comb begin
    crc_nxt = crc_out << 1;
    if (crc_next_bit) begin
      crc_nxt = crc_nxt ^ 15'h4599;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_out <= 15'h0000;
    end else if (clear) begin
      crc_out <= 15'h0000;
    end else if (enable) begin
      crc_out <= crc_nxt;
    end
  end

endmodule
