`timescale 1ns/1ps
import can_pkg::*;

module can_top (
  input  logic clk,
  input  logic rst_n,
  
  // Host Interface (Simplified AXI-Lite/APB style)
  input  logic        host_cs,
  input  logic        host_we,
  input  logic [7:0]  host_addr,
  input  logic [31:0] host_wdata,
  output logic [31:0] host_rdata,
  
  // Physical CAN Bus
  input  logic can_rx,
  output logic can_tx
);

  // Internal Signals
  bit_timing_t timing_cfg;
  logic sample_point, tx_point, rx_sync;
  logic can_tx_internal, can_rx_internal;
  
  // Instance: Bit Timing
  can_btr u_btr (
    .clk(clk),
    .rst_n(rst_n),
    .timing_cfg(timing_cfg),
    .rx_sync(rx_sync),
    .sample_point(sample_point),
    .tx_point(tx_point)
  );

  // Instance: TX Engine
  can_tx u_tx (
    .clk(clk),
    .rst_n(rst_n),
    .tx_frame('0), // Tied off for prototype compilation
    .tx_req(1'b0),
    .tx_ack(),
    .tx_done(),
    .tx_point(tx_point),
    .can_tx_out(can_tx_internal),
    .stuff_en(),
    .stuff_data_in(),
    .stuff_data_out(1'b1),
    .stuff_stall(1'b0)
  );
  
  // Instance: RX Engine
  can_rx u_rx (
    .clk(clk),
    .rst_n(rst_n),
    .rx_frame(),
    .rx_valid(),
    .sample_point(sample_point),
    .rx_sync(rx_sync),
    .can_rx_in(can_rx_internal),
    .destuff_bit(can_rx_internal),
    .destuff_err(1'b0)
  );
  
  // Instance: Fault Injector
  can_fault_injector u_fault (
    .clk(clk),
    .rst_n(rst_n),
    .can_tx_normal(can_tx_internal),
    .can_rx_normal(can_rx_internal),
    .can_tx_bus(can_tx),
    .can_rx_bus(can_rx),
    .inject_bit_err(1'b0),
    .inject_crc_err(1'b0),
    .inject_ack_err(1'b0),
    .inject_stuff_err(1'b0),
    .in_crc_phase(1'b0),
    .in_ack_phase(1'b0),
    .tx_point(tx_point)
  );

  // Basic Host Register interface
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      timing_cfg <= '0;
      host_rdata <= '0;
    end else if (host_cs) begin
      if (host_we) begin
        if (host_addr == 8'h00) timing_cfg <= host_wdata[14:0];
      end else begin
        if (host_addr == 8'h00) host_rdata <= {17'd0, timing_cfg};
      end
    end
  end

endmodule
