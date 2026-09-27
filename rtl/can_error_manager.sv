`timescale 1ns/1ps
import can_pkg::*;

module can_error_manager (
  input  logic clk,
  input  logic rst_n,
  
  // Error inputs from RX/TX engines
  input  logic bit_err,
  input  logic stuff_err,
  input  logic crc_err,
  input  logic ack_err,
  input  logic form_err,
  
  // Successful transmission/reception (decrements counters)
  input  logic rx_success,
  input  logic tx_success,
  
  // Status outputs
  output logic [7:0] tx_err_cnt,
  output logic [7:0] rx_err_cnt,
  output error_state_t err_state
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_err_cnt <= 8'd0;
      rx_err_cnt <= 8'd0;
      err_state <= ERROR_ACTIVE;
    end else begin
      // Basic TX Error Rules
      if (bit_err || ack_err || form_err) begin
        if (tx_err_cnt <= 8'd247) tx_err_cnt <= tx_err_cnt + 8'd8;
        else tx_err_cnt <= 8'd255;
      end else if (tx_success) begin
        if (tx_err_cnt > 0) tx_err_cnt <= tx_err_cnt - 1'b1;
      end
      
      // Basic RX Error Rules
      if (stuff_err || crc_err) begin
        if (rx_err_cnt <= 8'd247) rx_err_cnt <= rx_err_cnt + 8'd8;
        else rx_err_cnt <= 8'd255;
      end else if (rx_success) begin
        if (rx_err_cnt >= 8'd1 && rx_err_cnt <= 8'd127) rx_err_cnt <= rx_err_cnt - 1'b1;
        else if (rx_err_cnt > 8'd127) rx_err_cnt <= 8'd127; // Reset to error active range
      end

      // State determination
      if (tx_err_cnt >= 8'd255 || rx_err_cnt >= 8'd255) begin
        err_state <= BUS_OFF;
      end else if (tx_err_cnt >= 8'd128 || rx_err_cnt >= 8'd128) begin
        err_state <= ERROR_PASSIVE;
      end else begin
        err_state <= ERROR_ACTIVE;
      end
    end
  end

endmodule
