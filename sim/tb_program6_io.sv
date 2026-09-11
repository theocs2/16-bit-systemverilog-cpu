`timescale 1ns/1ps

module tb_program6_io;
    logic clk;
    logic reset;
    logic run_i;
    logic continue_i;
    logic [15:0] sw_i;

    logic [15:0] led_o;
    logic [7:0] hex_seg_o;
    logic [3:0] hex_grid_o;
    logic [7:0] hex_seg_debug;
    logic [3:0] hex_grid_debug;

    logic [15:0] sram_rdata;
    logic [15:0] sram_wdata;
    logic [15:0] sram_addr;
    logic        sram_mem_ena;
    logic        sram_wr_ena;

    localparam logic [15:0] PROGRAM_SELECT = 16'd6;
    localparam logic [15:0] FIRST_INPUT    = 16'h00A5;
    localparam logic [15:0] SECOND_INPUT   = 16'h003C;
    localparam logic [15:0] FIRST_PSE      = 16'h0801;
    localparam logic [15:0] SECOND_PSE     = 16'h0C02;

    processor_system dut (
        .clk(clk),
        .reset(reset),
        .run_i(run_i),
        .continue_i(continue_i),
        .sw_i(sw_i),
        .led_o(led_o),
        .hex_seg_o(hex_seg_o),
        .hex_grid_o(hex_grid_o),
        .hex_seg_debug(hex_seg_debug),
        .hex_grid_debug(hex_grid_debug),
        .sram_rdata(sram_rdata),
        .sram_wdata(sram_wdata),
        .sram_addr(sram_addr),
        .sram_mem_ena(sram_mem_ena),
        .sram_wr_ena(sram_wr_ena)
    );

    memory mem (
        .clk(clk),
        .reset(reset),
        .data(sram_wdata),
        .address(sram_addr[9:0]),
        .ena(sram_mem_ena),
        .wren(sram_wr_ena),
        .readout(sram_rdata)
    );

    always #5 clk = ~clk;

`ifdef DUMP_VCD
    initial begin
        $dumpfile("tb_program6_io.vcd");
        $dumpvars(0, tb_program6_io);
    end
`endif

    task automatic pulse_run;
        begin
            run_i = 1'b1;
            @(negedge clk);
            run_i = 1'b0;
        end
    endtask

    task automatic pulse_continue;
        begin
            continue_i = 1'b1;
            @(negedge clk);
            continue_i = 1'b0;
        end
    endtask

    task automatic wait_for_led(input logic [15:0] expected, input int timeout_cycles);
        int cycles;
        begin
            cycles = timeout_cycles;
            while ((led_o !== expected) && (cycles > 0)) begin
                @(negedge clk);
                cycles--;
            end

            if (led_o !== expected) begin
                $fatal(1, "Timed out waiting for led_o=%h, saw %h", expected, led_o);
            end
        end
    endtask

    task automatic wait_for_hex(input logic [15:0] expected, input int timeout_cycles);
        int cycles;
        begin
            cycles = timeout_cycles;
            while ((dut.io_bridge.hex_display !== expected) && (cycles > 0)) begin
                @(negedge clk);
                cycles--;
            end

            if (dut.io_bridge.hex_display !== expected) begin
                $fatal(1, "Timed out waiting for hex_display=%h, saw %h",
                       expected, dut.io_bridge.hex_display);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        run_i = 1'b0;
        continue_i = 1'b0;
        sw_i = PROGRAM_SELECT;

        repeat (2) @(negedge clk);
        reset = 1'b0;
        @(negedge clk);

        // Boot ROM:
        //   0: clear R0
        //   1: load switches into R1
        //   2: jump to address in R1
        // With sw_i = 6, the CPU jumps into program 6 from types.sv.
        pulse_run();

        // Program 6 ("Basic I/O test 2"):
        //   6: PSE x801
        //   7: LDR R1, R0, inSW
        //   8: STR R1, R0, outHEX
        //   9: PSE xC02
        //  10: BRnzp -4
        wait_for_led(FIRST_PSE, 80);
        if (dut.cpu.pc !== 16'd7) begin
            $fatal(1, "Expected PC=0007 after first pause, saw %h", dut.cpu.pc);
        end

        sw_i = FIRST_INPUT;
        pulse_continue();

        wait_for_hex(FIRST_INPUT, 80);
        wait_for_led(SECOND_PSE, 80);
        if (dut.cpu.r1 !== FIRST_INPUT) begin
            $fatal(1, "Expected R1=%h after first input, saw %h", FIRST_INPUT, dut.cpu.r1);
        end

        sw_i = SECOND_INPUT;
        pulse_continue();

        // BR -4 at address 10 returns to the input at address 7.
        // The initial checkpoint at address 6 is reached only once.
        wait_for_hex(SECOND_INPUT, 80);
        wait_for_led(SECOND_PSE, 80);
        if (dut.cpu.r1 !== SECOND_INPUT) begin
            $fatal(1, "Expected R1=%h after second input, saw %h", SECOND_INPUT, dut.cpu.r1);
        end

        $display("PASS: program 6 executed correctly.");
        $display("Final state: PC=%h IR=%h R1=%h HEX=%h LED=%h",
                 dut.cpu.pc, dut.cpu.ir, dut.cpu.r1, dut.io_bridge.hex_display, led_o);
        $finish;
    end
endmodule
