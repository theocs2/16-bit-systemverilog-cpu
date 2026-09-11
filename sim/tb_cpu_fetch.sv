`timescale 1ns/1ps

module tb_cpu_fetch;
    logic clk;
    logic reset;
    logic run_i;
    logic continue_i;

    logic [15:0] mem_rdata;
    logic [15:0] mem_wdata;
    logic [15:0] mem_addr;
    logic mem_mem_ena;
    logic mem_wr_ena;

    logic [15:0] hex_display_debug;
    logic [15:0] led_o;

    cpu dut (
        .clk(clk),
        .reset(reset),
        .run_i(run_i),
        .continue_i(continue_i),
        .hex_display_debug(hex_display_debug),
        .led_o(led_o),
        .mem_rdata(mem_rdata),
        .mem_wdata(mem_wdata),
        .mem_addr(mem_addr),
        .mem_mem_ena(mem_mem_ena),
        .mem_wr_ena(mem_wr_ena)
    );

    always #5 clk = ~clk;

    initial begin
        logic [15:0] pc_before_fetch;

        clk = 1'b0;
        reset = 1'b1;
        run_i = 1'b0;
        continue_i = 1'b0;
        mem_rdata = 16'hABCD;

        // Apply synchronous reset.
        repeat (2) @(negedge clk);

        reset = 1'b0;
        
        // Wait for a cycle in halted state
        @(negedge clk);
        
        run_i = 1'b1;

        // Enter s_18 on this edge.
        @(negedge clk);
        run_i = 1'b0; // Deassert run

        // ---------------------------------------------------------------------
        // Check PC loading into MAR and PC incrementing
        // ---------------------------------------------------------------------
        // s_18 executes on this edge: MAR <- PC and PC <- PC + 1.
        pc_before_fetch = dut.pc;
        $display("State S_18: PC is %h", pc_before_fetch);
        
        @(negedge clk);

        if (dut.mar === pc_before_fetch && dut.pc === pc_before_fetch + 16'd1) begin
            $display("PASS: PC->MAR and PC increment at t=%0t: PC(old)=%h MAR=%h PC(new)=%h",
                     $time, pc_before_fetch, dut.mar, dut.pc);
        end else begin
            $fatal(1, "FAIL: Expected MAR=%h and PC=%h, got MAR=%h PC=%h",
                   pc_before_fetch, pc_before_fetch + 16'd1, dut.mar, dut.pc);
        end

        // ---------------------------------------------------------------------
        // Check MDR loading into IR
        // ---------------------------------------------------------------------
        // Advance through s_33_1, s_33_2, s_33_3 to s_35.
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        // s_35 executes on this edge: IR <- MDR.
        @(negedge clk);

        if (dut.mdr === 16'hABCD && dut.ir === 16'hABCD) begin
            $display("PASS: MDR->IR at t=%0t: MDR=%h IR=%h", $time, dut.mdr, dut.ir);
        end else begin
            $fatal(1, "FAIL: Expected MDR=IR=ABCD, got MDR=%h IR=%h", dut.mdr, dut.ir);
        end

        $display("Simulation complete.");
        $finish;
    end
endmodule
