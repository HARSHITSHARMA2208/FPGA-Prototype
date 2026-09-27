import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_can_top_basic(dut):
    """Test CAN Top Level Basic Initialization"""
    
    # Generate 100MHz clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.host_cs.value = 0
    dut.host_we.value = 0
    dut.can_rx.value = 1 # Idle bus
    
    await Timer(50, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Write to Bit Timing register (Prescaler=1, TSEG1=10, TSEG2=3, SJW=1)
    # config = {prescaler: 8'd0, tseg1: 4'd9, tseg2: 3'd2, sjw: 2'd0}
    config_val = (0 << 9) | (9 << 5) | (2 << 2) | 0
    
    dut.host_cs.value = 1
    dut.host_we.value = 1
    dut.host_addr.value = 0x00
    dut.host_wdata.value = config_val
    await RisingEdge(dut.clk)
    
    dut.host_cs.value = 0
    dut.host_we.value = 0
    await RisingEdge(dut.clk)
    
    # Verify Read
    dut.host_cs.value = 1
    dut.host_we.value = 0
    dut.host_addr.value = 0x00
    await RisingEdge(dut.clk)
    
    assert int(dut.host_rdata.value) == config_val, f"Register read mismatch: Expected {config_val}, got {int(dut.host_rdata.value)}"
    
    # Wait some clocks to see bit timing logic run
    for _ in range(50):
        await RisingEdge(dut.clk)

    dut._log.info("Basic Initialization and Register Access Test Passed.")
