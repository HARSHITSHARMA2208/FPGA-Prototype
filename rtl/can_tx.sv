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
  input  logic       stuff_stall,
  
  // CRC
  output logic       crc_en,
  output logic       crc_clear,
  input  logic [14:0] crc_in
);

  typedef enum logic [3:0] {
    IDLE       = 4'd0,
    SOF        = 4'd1,
    ARB_ID     = 4'd2,
    ARB_RTR    = 4'd3,
    CTRL_IDE   = 4'd4,
    CTRL_R0    = 4'd5,
    CTRL_DLC   = 4'd6,
    DATA       = 4'd7,
    CRC_SEQ    = 4'd8,
    CRC_DELIM  = 4'd9,
    ACK_SLOT   = 4'd10,
    ACK_DELIM  = 4'd11,
    EOF        = 4'd12,
    INTERFRAME = 4'd13
  } tx_state_t;
  
  tx_state_t state, next_state;
  logic [3:0] bit_cnt, next_bit_cnt;
  logic [2:0] byte_cnt, next_byte_cnt;
  logic shift_bit;

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

  always_comb begin
    next_state = state;
    next_bit_cnt = bit_cnt;
    next_byte_cnt = byte_cnt;
    shift_bit = 1'b1; // recessive default
    stuff_en = 1'b0;
    stuff_data_in = 1'b1;
    tx_ack = 1'b0;
    tx_done = 1'b0;
    crc_en = 1'b0;
    crc_clear = 1'b0;

    case (state)
      IDLE: begin
        crc_clear = 1'b1;
        if (tx_req) begin
          next_state = SOF;
          tx_ack = 1'b1;
        end
      end
      
      SOF: begin
        shift_bit = 1'b0; // Dominant
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        crc_en = 1'b1;
        next_state = ARB_ID;
        next_bit_cnt = 4'd10;
      end
      
      ARB_ID: begin
        shift_bit = tx_frame.id[bit_cnt];
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        crc_en = 1'b1;
        if (bit_cnt == 0) next_state = ARB_RTR;
        else next_bit_cnt = bit_cnt - 1;
      end
      
      ARB_RTR: begin
        shift_bit = tx_frame.rtr;
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        crc_en = 1'b1;
        next_state = CTRL_IDE;
      end
      
      CTRL_IDE: begin
        shift_bit = 1'b0; // Standard format
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        crc_en = 1'b1;
        next_state = CTRL_R0;
      end
      
      CTRL_R0: begin
        shift_bit = 1'b0; // Reserved bit dominant
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        crc_en = 1'b1;
        next_state = CTRL_DLC;
        next_bit_cnt = 4'd3;
      end
      
      CTRL_DLC: begin
        shift_bit = tx_frame.dlc[bit_cnt];
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        crc_en = 1'b1;
        if (bit_cnt == 0) begin
          if (tx_frame.dlc == 0 || tx_frame.rtr == 1'b1) begin
            next_state = CRC_SEQ;
            next_bit_cnt = 4'd14;
          end else begin
            next_state = DATA;
            next_bit_cnt = 4'd7;
            next_byte_cnt = 3'd0;
          end
        end else begin
          next_bit_cnt = bit_cnt - 1;
        end
      end
      
      DATA: begin
        shift_bit = tx_frame.data[byte_cnt][bit_cnt];
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        crc_en = 1'b1;
        if (bit_cnt == 0) begin
          if (byte_cnt == tx_frame.dlc - 1) begin
            next_state = CRC_SEQ;
            next_bit_cnt = 4'd14;
          end else begin
            next_byte_cnt = byte_cnt + 1;
            next_bit_cnt = 4'd7;
          end
        end else begin
          next_bit_cnt = bit_cnt - 1;
        end
      end
      
      CRC_SEQ: begin
        shift_bit = crc_in[bit_cnt];
        stuff_en = 1'b1;
        stuff_data_in = shift_bit;
        if (bit_cnt == 0) next_state = CRC_DELIM;
        else next_bit_cnt = bit_cnt - 1;
      end
      
      CRC_DELIM: begin
        shift_bit = 1'b1; // Recessive
        stuff_en = 1'b0;  // No stuffing from here
        next_state = ACK_SLOT;
      end
      
      ACK_SLOT: begin
        shift_bit = 1'b1; // Recessive (waiting for receiver dominant)
        stuff_en = 1'b0;
        next_state = ACK_DELIM;
      end
      
      ACK_DELIM: begin
        shift_bit = 1'b1;
        next_state = EOF;
        next_bit_cnt = 4'd6;
      end
      
      EOF: begin
        shift_bit = 1'b1;
        if (bit_cnt == 0) begin
           next_state = INTERFRAME;
           next_bit_cnt = 4'd2;
           tx_done = 1'b1;
        end else next_bit_cnt = bit_cnt - 1;
      end
      
      INTERFRAME: begin
        shift_bit = 1'b1;
        if (bit_cnt == 0) next_state = IDLE;
        else next_bit_cnt = bit_cnt - 1;
      end
    endcase
  end

  // Output formatting
  always_comb begin
    if (state == IDLE || state == INTERFRAME) begin
      can_tx_out = 1'b1; // Bus idle recessive
    end else begin
      can_tx_out = stuff_en ? stuff_data_out : shift_bit;
    end
  end

endmodule
