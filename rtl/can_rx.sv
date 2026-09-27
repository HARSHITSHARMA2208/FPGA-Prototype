`timescale 1ns/1ps
import can_pkg::*;

module can_rx (
  input  logic clk,
  input  logic rst_n,
  
  // Interface to Application / FIFO
  output can_frame_t rx_frame,
  output logic       rx_valid,
  
  // Bit Timing sync
  input  logic       sample_point,
  output logic       rx_sync, // Resynchronization pulse
  
  // Bus Interface
  input  logic       can_rx_in,
  
  // Destuffing interface
  input  logic       destuff_bit,
  input  logic       destuff_err
);

  typedef enum logic [3:0] {
    IDLE,
    SOF,
    ARB_ID,
    ARB_RTR,
    CTRL_IDE,
    CTRL_R0,
    CTRL_DLC,
    DATA,
    CRC_READ,
    CRC_DELIM,
    ACK_GEN,
    ACK_DELIM,
    EOF,
    INTERFRAME
  } rx_state_t;
  
  rx_state_t state, next_state;
  logic [3:0] bit_cnt;
  logic [2:0] byte_cnt;
  
  // Sync logic (simplified hard sync on SOF)
  logic last_rx;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last_rx <= 1'b1;
      rx_sync <= 1'b0;
    end else begin
      last_rx <= can_rx_in;
      // Falling edge detection for resync
      rx_sync <= (last_rx == 1'b1 && can_rx_in == 1'b0);
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_cnt <= '0;
      byte_cnt <= '0;
      rx_valid <= 1'b0;
    end else if (sample_point) begin
      // Default actions
      rx_valid <= 1'b0;
      
      case (state)
        IDLE: begin
          if (can_rx_in == 1'b0) begin // SOF detected
            state <= ARB_ID;
            bit_cnt <= 4'd10;
          end
        end
        ARB_ID: begin
          rx_frame.id[bit_cnt] <= destuff_bit;
          if (bit_cnt == 0) state <= ARB_RTR;
          else bit_cnt <= bit_cnt - 1;
        end
        // Other states simplified
        // ...
      endcase
    end
  end

endmodule
