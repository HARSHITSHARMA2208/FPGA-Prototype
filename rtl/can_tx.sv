`timescale 1ns/1ps
import can_pkg::*;

module can_tx (
  input  logic clk,
  input  logic rst_n,
  
  // Interface to Application / FIFO
  input  can_frame_t tx_frame,
  input  logic       tx_req,
  output logic       tx_ack,
  output logic       tx_done,
  
  // Bit Timing sync
  input  logic       tx_point,
  
  // Bus Interface
  output logic       can_tx_out,
  
  // Stuffing interface
  output logic       stuff_en,
  output logic       stuff_data_in,
  input  logic       stuff_data_out,
  input  logic       stuff_stall
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
    CRC_CALC,
    CRC_DELIM,
    ACK,
    ACK_DELIM,
    EOF,
    INTERFRAME
  } tx_state_t;
  
  tx_state_t state, next_state;
  logic [3:0] bit_cnt, next_bit_cnt;
  logic [2:0] byte_cnt, next_byte_cnt;
  logic shift_bit;

  // TX FSM
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_cnt <= '0;
      byte_cnt <= '0;
    end else if (tx_point && !stuff_stall) begin
      state <= next_state;
      bit_cnt <= next_bit_cnt;
      byte_cnt <= next_byte_cnt;
    end
  end

  // Next State Logic (Simplified)
  always_comb begin
    next_state = state;
    next_bit_cnt = bit_cnt;
    next_byte_cnt = byte_cnt;
    shift_bit = 1'b1; // recessive default
    stuff_en = 1'b0;
    stuff_data_in = 1'b1;
    tx_ack = 1'b0;
    tx_done = 1'b0;

    case (state)
      IDLE: begin
        if (tx_req) begin
          next_state = SOF;
          tx_ack = 1'b1;
        end
      end
      SOF: begin
        shift_bit = 1'b0; // Dominant
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        next_state = ARB_ID;
        next_bit_cnt = 4'd10;
      end
      ARB_ID: begin
        shift_bit = tx_frame.id[bit_cnt];
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        if (bit_cnt == 0) next_state = ARB_RTR;
        else next_bit_cnt = bit_cnt - 1;
      end
      // Remaining states simplified for prototype structure
      // ...
    endcase
  end

  // Output formatting
  always_comb begin
    can_tx_out = stuff_en ? stuff_data_out : shift_bit;
  end

endmodule
