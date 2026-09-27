`timescale 1ns/1ps

module fpga_can_demo (
  input  logic clk_100m,
  input  logic btn_rst,
  
  // External CAN Transceiver pins
  input  logic can_rx_ext,
  output logic can_tx_ext,
  
  // LED Status
  output logic led_tx_active,
  output logic led_rx_active,
  output logic led_err_state,
  output logic led_bus_off
);

  // NOTE: This demo requires an external CAN transceiver (e.g., MCP2551, TJA1050)
  // to convert standard logic levels (can_tx_ext, can_rx_ext) to CAN differential 
  // signals (CANH, CANL).
  
  logic rst_n;
  assign rst_n = ~btn_rst;
  
  logic tx_active_int;
  logic rx_active_int;
  logic [1:0] err_state;
  
  // Dummy Host interface for demo
  logic        host_cs;
  logic        host_we;
  logic [7:0]  host_addr;
  logic [31:0] host_wdata;
  logic [31:0] host_rdata;

  // Initialize at startup
  always_ff @(posedge clk_100m or negedge rst_n) begin
    if (!rst_n) begin
      host_cs <= 1'b0;
      host_we <= 1'b0;
      host_addr <= '0;
      host_wdata <= '0;
    end else begin
      // Simple startup sequence to set bit timing
      // ... (FSM to configure CAN controller would go here)
    end
  end

  can_top u_can_ctrl (
    .clk(clk_100m),
    .rst_n(rst_n),
    .host_cs(host_cs),
    .host_we(host_we),
    .host_addr(host_addr),
    .host_wdata(host_wdata),
    .host_rdata(host_rdata),
    .can_rx(can_rx_ext),
    .can_tx(can_tx_ext)
  );

  // Map internal states to LEDs (simplified)
  assign led_tx_active = 1'b0; // Tap from internal state
  assign led_rx_active = 1'b0; // Tap from internal state
  assign led_err_state = (err_state == 2'b01); // Error Passive
  assign led_bus_off   = (err_state == 2'b10); // Bus Off

endmodule
