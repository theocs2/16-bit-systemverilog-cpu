`timescale 1ns / 1ps

module testbench();

// 1. Time Domain Parameters
parameter CLK_PERIOD = 10;

// 2. DUT Signals
logic clk;
logic reset;
logic run_i;
logic continue_i;
logic [15:0] sw_i;

logic [15:0] led_o;
logic [7:0] hex_seg_left;
logic [3:0] hex_grid_left;
logic [7:0] hex_seg_right;
logic [3:0] hex_grid_right;

// 3. Instantiate Top-Level Module
processor_top dut (
.clk(clk),
.reset(reset),
.run_i(run_i),
.continue_i(continue_i),
.sw_i(sw_i),
.led_o(led_o),
.hex_seg_left(hex_seg_left),
.hex_grid_left(hex_grid_left),
.hex_seg_right(hex_seg_right),
.hex_grid_right(hex_grid_right)
);

// 4. Clock Generation
initial begin
clk = 1'b0;
forever #(CLK_PERIOD / 2) clk = ~clk;
end

// 5. Stimulus Generation
initial begin
// Initialize all inputs
reset = 1'b0;
run_i = 1'b0;
continue_i = 1'b0;
sw_i = 16'h0000;

// Apply Reset
#20;
reset = 1'b1;
#50;
reset = 1'b0;

// Wait for reset to propagate
#100;

$display("--- BUBBLE SORT SIMULATION START ---");

// Select bubble sort program start address = decimal 90 = 0x005A
sw_i = 16'h005A;
#100;

// Pulse run to start CPU
run_i = 1'b1;
#500;
run_i = 1'b0;

// Wait long enough to reach bubble sort menu checkpoint
#2000;

$display("-> Selecting sort function.");
// Menu choice 2 = sort function
sw_i = 16'h0002;

// Pulse continue to leave menu and start sort
#100;
continue_i = 1'b1;
#100;
continue_i = 1'b0;

// Let the sort routine run for a long time
#2000000;

$display("--- BUBBLE SORT SIMULATION COMPLETE ---");

$finish;
end

endmodule
