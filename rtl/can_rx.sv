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
  input  logic       destuff_err,
  
  // CRC checks
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
    CRC_READ   = 4'd8,
    CRC_DELIM  = 4'd9,
    ACK_GEN    = 4'd10,
    ACK_DELIM  = 4'd11,
    EOF        = 4'd12,
    INTERFRAME = 4'd13
  } rx_state_t;
  
  rx_state_t state;
  logic [3:0] bit_cnt;
  logic [2:0] byte_cnt;
  
  logic [14:0] rx_crc_seq;
  
  // Sync logic (simplified hard sync on SOF)
  logic last_rx;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last_rx <= 1'b1;
      rx_sync <= 1'b0;
    end else begin
      last_rx <= can_rx_in;
      // Falling edge detection for resync when idle
      if (state == IDLE || state == INTERFRAME) begin
        rx_sync <= (last_rx == 1'b1 && can_rx_in == 1'b0);
      end else begin
        rx_sync <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_cnt <= '0;
      byte_cnt <= '0;
      rx_valid <= 1'b0;
      rx_frame <= '0;
      crc_en <= 1'b0;
      crc_clear <= 1'b1;
    end else if (sample_point) begin
      rx_valid <= 1'b0;
      crc_en <= 1'b0;
      crc_clear <= 1'b0;
      
      case (state)
        IDLE: begin
          crc_clear <= 1'b1;
          if (can_rx_in == 1'b0) begin // SOF detected
            state <= ARB_ID;
            bit_cnt <= 4'd10;
            crc_en <= 1'b1; // Start CRC over SOF
          end
        end
        
        ARB_ID: begin
          rx_frame.id[bit_cnt] <= destuff_bit;
          crc_en <= 1'b1;
          if (bit_cnt == 0) state <= ARB_RTR;
          else bit_cnt <= bit_cnt - 1;
        end
        
        ARB_RTR: begin
          rx_frame.rtr <= destuff_bit;
          crc_en <= 1'b1;
          state <= CTRL_IDE;
        end
        
        CTRL_IDE: begin
          // Standard only for this prototype
          crc_en <= 1'b1;
          state <= CTRL_R0;
        end
        
        CTRL_R0: begin
          crc_en <= 1'b1;
          state <= CTRL_DLC;
          bit_cnt <= 4'd3;
        end
        
        CTRL_DLC: begin
          rx_frame.dlc[bit_cnt] <= destuff_bit;
          crc_en <= 1'b1;
          if (bit_cnt == 0) begin
            // Need next state logic based on current bit
            logic [3:0] temp_dlc;
            temp_dlc = rx_frame.dlc;
            temp_dlc[0] = destuff_bit; // Incorporate current bit
            
            if (temp_dlc == 0 || rx_frame.rtr == 1'b1) begin
              state <= CRC_READ;
              bit_cnt <= 4'd14;
            end else begin
              state <= DATA;
              bit_cnt <= 4'd7;
              byte_cnt <= 3'd0;
            end
          end else begin
            bit_cnt <= bit_cnt - 1;
          end
        end
        
        DATA: begin
          rx_frame.data[byte_cnt][bit_cnt] <= destuff_bit;
          crc_en <= 1'b1;
          if (bit_cnt == 0) begin
            if (byte_cnt == rx_frame.dlc - 1) begin
              state <= CRC_READ;
              bit_cnt <= 4'd14;
            end else begin
              byte_cnt <= byte_cnt + 1;
              bit_cnt <= 4'd7;
            end
          end else begin
            bit_cnt <= bit_cnt - 1;
          end
        end
        
        CRC_READ: begin
          rx_crc_seq[bit_cnt] <= destuff_bit;
          if (bit_cnt == 0) state <= CRC_DELIM;
          else bit_cnt <= bit_cnt - 1;
        end
        
        CRC_DELIM: begin
          state <= ACK_GEN;
        end
        
        ACK_GEN: begin
          // In a real controller, we assert dominant here if CRC matches
          state <= ACK_DELIM;
        end
        
        ACK_DELIM: begin
          state <= EOF;
          bit_cnt <= 4'd6;
        end
        
        EOF: begin
          if (bit_cnt == 0) begin
             state <= INTERFRAME;
             bit_cnt <= 4'd2;
             rx_valid <= 1'b1; // Frame fully received
          end else bit_cnt <= bit_cnt - 1;
        end
        
        INTERFRAME: begin
          if (bit_cnt == 0) state <= IDLE;
          else bit_cnt <= bit_cnt - 1;
        end
      endcase
    end
  end

endmodule
