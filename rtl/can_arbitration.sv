`timescale 1ns/1ps

module can_arbitration (
  input  logic clk,
  input  logic rst_n,
  
  input  logic tx_point,
  input  logic sample_point,
  
  input  logic can_tx_out,  // What the controller is transmitting
  input  logic can_rx_in,   // What the bus is reading
  
  input  logic in_arbitration_phase, // High during SOF and ID phases
  
  output logic arbitration_lost // Asserted if TX sends recessive but reads dominant
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arbitration_lost <= 1'b0;
    end else if (sample_point && in_arbitration_phase) begin
      // Arbitration loss: transmitting 1 (recessive) but bus is 0 (dominant)
      if (can_tx_out == 1'b1 && can_rx_in == 1'b0) begin
        arbitration_lost <= 1'b1;
      end
    end else if (!in_arbitration_phase) begin
      arbitration_lost <= 1'b0; // Clear outside arbitration phase
    end
  end

endmodule
