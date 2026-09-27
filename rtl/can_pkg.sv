package can_pkg;

  // CAN 2.0 Standard Frame Parameters
  localparam int CAN_ID_W       = 11;
  localparam int CAN_DLC_W      = 4;
  localparam int CAN_DATA_W     = 8;
  localparam int CAN_CRC_W      = 15;
  
  // Bit Timing configuration types
  typedef struct packed {
    logic [7:0] prescaler; // Baud rate prescaler
    logic [3:0] tseg1;     // Time segment 1
    logic [2:0] tseg2;     // Time segment 2
    logic [1:0] sjw;       // Synchronization jump width
  } bit_timing_t;

  // Frame type
  typedef struct packed {
    logic [CAN_ID_W-1:0] id;
    logic                rtr;
    logic [CAN_DLC_W-1:0] dlc;
    logic [7:0][7:0]     data; // Up to 8 bytes
  } can_frame_t;

  // Error States
  typedef enum logic [1:0] {
    ERROR_ACTIVE = 2'b00,
    ERROR_PASSIVE = 2'b01,
    BUS_OFF = 2'b10
  } error_state_t;

endpackage : can_pkg
