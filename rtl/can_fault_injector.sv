`timescale 1ns/1ps

module can_fault_injector (
  input  logic clk,
  input  logic rst_n,
  
  // Normal Bus paths
  input  logic can_tx_normal,
  output logic can_rx_normal,
  
  // Physical Bus paths
  output logic can_tx_bus,
  input  logic can_rx_bus,
  
  // Fault triggers (from registers/testbench)
  input  logic inject_bit_err,   // Invert TX bit
  input  logic inject_crc_err,   // Corrupt CRC
  input  logic inject_ack_err,   // Don't send ACK
  input  logic inject_stuff_err, // Force 6 identical bits
  
  // Phase indications from Controller
  input  logic in_crc_phase,
  input  logic in_ack_phase,
  input  logic tx_point
);

  logic tx_faulted;
  
  always_comb begin
    tx_faulted = can_tx_normal;
    
    if (inject_bit_err) begin
      tx_faulted = ~can_tx_normal;
    end
    
    if (inject_crc_err && in_crc_phase) begin
      tx_faulted = ~can_tx_normal; // Flip bits during CRC
    end
    
    if (inject_ack_err && in_ack_phase) begin
      tx_faulted = 1'b1; // Send recessive instead of dominant ACK
    end
    
    // Stuff error needs a counter, simplified here as forcing dominant
    if (inject_stuff_err) begin
       tx_faulted = 1'b0; 
    end
  end

  // Register the physical output to avoid combinational loops if bus is looped back externally
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_tx_bus <= 1'b1; // Recessive idle
      can_rx_normal <= 1'b1;
    end else begin
      if (tx_point) begin
        can_tx_bus <= tx_faulted;
      end
      can_rx_normal <= can_rx_bus;
    end
  end

endmodule
