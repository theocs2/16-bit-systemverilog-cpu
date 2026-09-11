//------------------------------------------------------------------------------
// Company: 		 UIUC ECE Dept.
// Engineer:		 Stephen Kempf
//
// Create Date:    
// Design Name:    16-bit processor core
// Module Name:    processor_system
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 09-22-2015 
//    Revised 06-09-2020
//	  Revised 03-02-2021
//    Xilinx vivado
//    Revised 07-25-2023 
//    Revised 12-29-2023
//    Revised 09-25-2024
//------------------------------------------------------------------------------

module cpu (
    input   logic        clk,
    input   logic        reset,

    input   logic        run_i,
    input   logic        continue_i,
    output  logic [15:0] hex_display_debug,
    output  logic [15:0] led_o,
   
    input   logic [15:0] mem_rdata,
    output  logic [15:0] mem_wdata,
    output  logic [15:0] mem_addr,
    output  logic        mem_mem_ena,
    output  logic        mem_wr_ena
);


// Datapath control and register signals
logic ld_mar; 
logic ld_mdr; 
logic ld_ir; 
logic ld_pc; 
logic ld_led;

logic gate_pc;
logic gate_mdr;

logic [1:0] pcmux; //select signals used to drive PCMUX

logic [15:0] mar; 
logic [15:0] mdr;
logic [15:0] ir;
logic [15:0] pc, pc_next; // pc's next defined here
logic [15:0] bus_val;

logic ben;
logic mio_en; // decides whether MDR gets loaded from CPU or bus

logic ld_reg;
logic ld_cc;
logic ld_ben;
logic gate_alu;
logic gate_marmux;
logic sr1mux;
logic sr2mux;
logic addr1mux;
logic [1:0] addr2mux;
logic drmux;
logic [1:0] aluk;

logic [15:0] sr1_val, sr2_val;
logic [2:0] sr1_reg, sr2_reg, dr_reg;

logic [15:0] sext_imm5, sext_imm6, sext_imm9, sext_imm11;

logic [15:0] alu_b, alu_val;
logic [15:0] addr1_val, addr2_val;
logic [15:0] addr_plus_val;

logic n, z, p;

logic [15:0] led_reg;

assign mem_addr = mar;
assign mem_wdata = mdr;


// main bus select logic
always_comb begin
    if (gate_pc) begin
        bus_val = pc;
    end
    else if (gate_mdr) begin
        bus_val = mdr;
    end
    else if (gate_alu) begin
        bus_val = alu_val;
    end
    else if (gate_marmux) begin
        bus_val = addr_plus_val; 
    end
    else begin
        bus_val = 16'h0000; 
    end
end

// PC select logic

always_comb begin
    unique case (pcmux) 
        2'b00   :   pc_next = pc + 1;
        2'b01   :   pc_next = bus_val;
        2'b10   :   pc_next = addr_plus_val;
        default :   pc_next = pc + 1; // default is PC <- PC+1
    endcase
end


// MDR 2:1 mux

logic [15:0] mdr_input;
assign mdr_input = mio_en ? mem_rdata : bus_val;

// sign extension values

assign sext_imm5 = {{11{ir[4]}}, ir[4:0]};
assign sext_imm6 = {{10{ir[5]}}, ir[5:0]};
assign sext_imm9 = {{7{ir[8]}}, ir[8:0]};
assign sext_imm11 = {{5{ir[10]}}, ir[10:0]};

// addr1 2:1 mux

assign addr1_val = (addr1mux) ? sr1_val : pc; 

// addr2mux 4:1 mux

always_comb begin
    unique case (addr2mux)
        2'b00 : addr2_val = 16'h0000;
        2'b01 : addr2_val = sext_imm6;
        2'b10 : addr2_val = sext_imm9;
        2'b11 : addr2_val = sext_imm11;
        default : addr2_val = 16'h0000;
    endcase
end

assign addr_plus_val = addr1_val + addr2_val; // addr plus

// register load things for reg file (top right of datapath)

logic [15:0] r0, r1, r2, r3, r4, r5, r6, r7;

// reg file assigning MUXes / logic

assign sr1_reg = (sr1mux) ? ir[8:6] : ir[11:9];
assign sr2_reg = ir[2:0];
assign dr_reg = (drmux) ? 3'b111 : ir[11:9];

always_comb begin // Setting sr1 and sr2 values (combinational)
    sr1_val = 16'h0000;
    sr2_val = 16'h0000;
    unique case (sr1_reg)
    3'b000 : sr1_val = r0;
    3'b001 : sr1_val = r1;
    3'b010 : sr1_val = r2;
    3'b011 : sr1_val = r3;
    3'b100 : sr1_val = r4;
    3'b101 : sr1_val = r5;
    3'b110 : sr1_val = r6;
    3'b111 : sr1_val = r7;
    default : ;
    endcase

    unique case (sr2_reg)
    3'b000 : sr2_val = r0;
    3'b001 : sr2_val = r1;
    3'b010 : sr2_val = r2;
    3'b011 : sr2_val = r3;
    3'b100 : sr2_val = r4;
    3'b101 : sr2_val = r5;
    3'b110 : sr2_val = r6;
    3'b111 : sr2_val = r7;
    default : ;
    endcase
end

always_ff @(posedge clk) begin // reset and setting register values through dr selection (clocked)
    if (reset) begin 
        r0 <= 16'h0000;
        r1 <= 16'h0000;
        r2 <= 16'h0000;
        r3 <= 16'h0000;
        r4 <= 16'h0000;
        r5 <= 16'h0000;
        r6 <= 16'h0000;
        r7 <= 16'h0000;
    end
    else if (ld_reg) begin
        unique case (dr_reg)
        3'b000 : r0 <= bus_val;
        3'b001 : r1 <= bus_val;
        3'b010 : r2 <= bus_val;
        3'b011 : r3 <= bus_val;
        3'b100 : r4 <= bus_val;
        3'b101 : r5 <= bus_val;
        3'b110 : r6 <= bus_val;
        3'b111 : r7 <= bus_val;
        default : ;
        endcase
    end
end

// sr2mux 2:1 mux , goes into alu_b

assign alu_b = (sr2mux) ? sext_imm5 : sr2_val;

// ALU 4 options

always_comb begin
    unique case (aluk) 
    2'b00 : alu_val = sr1_val + alu_b;
    2'b01 : alu_val = sr1_val & alu_b;
    2'b10 : alu_val = ~sr1_val;
    2'b11 : alu_val = sr1_val;
    default : alu_val = sr1_val + alu_b;
    endcase
end

// BEN stuff and setting CC, (clocked)

always_ff @(posedge clk) begin
    if (reset) begin
        n <= 1'b0;
        z <= 1'b0;
        p <= 1'b0;
        ben <= 1'b0;
    end 
    else begin
        if (ld_cc) begin
            n <= bus_val[15];
            z <= (bus_val == 16'h0000);
            p <= (~bus_val[15]) & (bus_val != 16'h0000);
        end
        if (ld_ben) begin
            ben <= ((ir[11] & n) | (ir[10] & z) | (ir[9] & p));
        end
    end
end

// Finite-state control for instruction fetch, decode, and execution
// .* auto-infers module input/output connections which have the same name
// This can help visually condense modules with large instantiations, 
// but can also lead to confusing code if used too commonly
control cpu_control (
    .*
);

always_ff @(posedge clk) begin
    if (reset) led_reg <= 16'h0000;
    else if (ld_led) led_reg <= {4'h0, ir[11:0]};
end

assign led_o = led_reg;
assign hex_display_debug = ir;

//register file below

load_reg #(.DATA_WIDTH(16)) ir_reg (
    .clk    (clk),
    .reset  (reset),

    .load   (ld_ir),
    .data_i (bus_val), //respective inputs go here

    .data_q (ir)
);

load_reg #(.DATA_WIDTH(16)) pc_reg (
    .clk(clk),
    .reset(reset),

    .load(ld_pc),
    .data_i(pc_next),

    .data_q(pc)
);

load_reg #(.DATA_WIDTH(16)) mar_reg (
    .clk(clk),
    .reset(reset),

    .load(ld_mar),
    .data_i(bus_val),

    .data_q(mar)
);

load_reg #(.DATA_WIDTH(16)) mdr_reg (
    .clk(clk),
    .reset(reset),

    .load(ld_mdr),
    .data_i(mdr_input),

    .data_q(mdr)
);

endmodule
