`timescale 1ns/1ps

module can_fifo #(
  parameter DATA_WIDTH = 128, // Matches can_frame_t size approx
  parameter DEPTH = 16
)(
  input  logic clk,
  input  logic rst_n,
  
  // Write interface
  input  logic [DATA_WIDTH-1:0] wdata,
  input  logic                  wen,
  output logic                  full,
  
  // Read interface
  output logic [DATA_WIDTH-1:0] rdata,
  input  logic                  ren,
  output logic                  empty
);

  localparam ADDR_WIDTH = $clog2(DEPTH);
  
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_WIDTH:0] wptr, rptr;

  assign full = (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) && 
                (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0]);
  assign empty = (wptr == rptr);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= '0;
    end else if (wen && !full) begin
      mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
      wptr <= wptr + 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rptr <= '0;
      rdata <= '0;
    end else if (ren && !empty) begin
      rdata <= mem[rptr[ADDR_WIDTH-1:0]];
      rptr <= rptr + 1'b1;
    end
  end

endmodule
