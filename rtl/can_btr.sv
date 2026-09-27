`timescale 1ns/1ps

import can_pkg::*;

module can_btr (
  input  logic clk,
  input  logic rst_n,
  
  input  bit_timing_t timing_cfg,
  input  logic rx_sync, // Sync edge detected
  
  output logic sample_point,
  output logic tx_point
);

  logic [7:0] tq_cnt;
  logic [4:0] seg_cnt;
  logic tq_tick;

  // Time Quantum (TQ) generator
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tq_cnt <= 8'd0;
      tq_tick <= 1'b0;
    end else begin
      if (tq_cnt == timing_cfg.prescaler) begin
        tq_cnt <= 8'd0;
        tq_tick <= 1'b1;
      end else begin
        tq_cnt <= tq_cnt + 1'b1;
        tq_tick <= 1'b0;
      end
    end
  end

  // Bit segment counter
  logic [4:0] total_tq;
  assign total_tq = 5'd1 + timing_cfg.tseg1 + timing_cfg.tseg2;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      seg_cnt <= 5'd0;
      sample_point <= 1'b0;
      tx_point <= 1'b0;
    end else begin
      sample_point <= 1'b0;
      tx_point <= 1'b0;
      
      if (rx_sync) begin
        seg_cnt <= 5'd0; // Resynchronization
      end else if (tq_tick) begin
        if (seg_cnt == total_tq - 1) begin
          seg_cnt <= 5'd0;
          tx_point <= 1'b1;
        end else begin
          seg_cnt <= seg_cnt + 1'b1;
        end
        
        if (seg_cnt == timing_cfg.tseg1) begin
          sample_point <= 1'b1;
        end
      end
    end
  end

endmodule
