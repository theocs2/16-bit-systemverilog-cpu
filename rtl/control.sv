//------------------------------------------------------------------------------
// Company:          UIUC ECE Dept.
// Engineer:         Stephen Kempf
//
// Create Date:    17:44:03 10/08/06
// Design Name:    16-bit processor control
// Module Name:    Control - Behavioral
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 02-13-2017
//    Spring 2017 Distribution
//    Revised 07-25-2023
//    Xilinx Vivado
//	  Revised 12-29-2023
// 	  Spring 2024 Distribution
// 	  Revised 6-22-2024
//	  Summer 2024 Distribution
//	  Revised 9-27-2024
//	  Fall 2024 Distribution
//------------------------------------------------------------------------------

module control (
	input logic			clk, 
	input logic			reset,

	input logic  [15:0]	ir,
	input logic			ben,

	input logic 		continue_i,
	input logic 		run_i,

	output logic		ld_mar,
	output logic		ld_mdr,
	output logic		ld_ir,
	output logic		ld_pc,
	output logic        ld_led,		
	output logic		gate_pc,
	output logic		gate_mdr,					
	output logic [1:0]	pcmux,	
	output logic 		mio_en,
	
// Execution controls
	output logic		ld_reg,
	output logic 		ld_cc,	
	output logic 		ld_ben,
	output logic		mem_mem_ena, // Mem Operation Enable
	output logic		mem_wr_ena,  // Mem Write Enable

	output logic 		gate_alu,
	output logic 		gate_marmux,

	output logic  		sr1mux,
	output logic 		sr2mux,
	output logic 		addr1mux,
	output logic [1:0] 	addr2mux,
	output logic [1:0] 	aluk, // ADD = 00, AND = 01, NOT A = 10, PASS A = 11
	output logic 		drmux
);

	enum logic [4:0] {
		halted, 
		pause_ir1,
		pause_ir2, 
		s_18, 
		s_33_1,
		s_33_2,
		s_33_3,
		s_35,
		s_32,
		s_1,
		s_5,
		s_9, 
		s_6,
		s_25_1,
		s_25_2,
		s_25_3,
		s_27,
		s_7,
		s_23,
		s_16_1,
		s_16_2,
		s_16_3,
		s_0,
		s_22,
		s_12,
		s_4,
		s_21
	} state, state_nxt;   // Internal state logic



	logic [3:0] opcode;
	logic [4:0]	ir_imm5;
	logic		ir_jsr;

	assign opcode = ir[15:12];
	assign ir_imm5 = ir[4:0];
	assign ir_jsr = ir[11]; //convenient


	always_ff @ (posedge clk)
	begin
		if (reset) 
			state <= halted;
		else 
			state <= state_nxt;
	end
   
	always_comb
	begin 
		
		// Default controls signal values so we don't have to set each signal
		// in each state case below (If we don't set all signals in each state,
		// we can create an inferred latch)
		ld_mar = 1'b0;
		ld_mdr = 1'b0;
		ld_ir = 1'b0;
		ld_pc = 1'b0;
		ld_led = 1'b0;
		gate_pc = 1'b0;
		gate_mdr = 1'b0;
		pcmux = 2'b00;
		mio_en = 1'b0;

		ld_reg = 1'b0;
		ld_cc = 1'b0;
		ld_ben = 1'b0;
		mem_mem_ena = 1'b0;
		mem_wr_ena = 1'b0;

		gate_alu = 1'b0;
		gate_marmux = 1'b0;

		sr1mux = 1'b0;
		sr2mux = 1'b0;
		addr1mux = 1'b0;
		addr2mux = 2'b00;
		aluk = 2'b00;
		drmux = 1'b0;

		// Assign relevant control signals based on current state
		case (state)
			halted: ; 
			s_18 : 
				begin 
					gate_pc = 1'b1;
					ld_mar = 1'b1;
					pcmux = 2'b00;
					ld_pc = 1'b1;
				end
			s_33_1, s_33_2, s_33_3 : //you may have to think about this as well to adapt to ram with wait-states
				begin
					mem_mem_ena = 1'b1;
					ld_mdr = 1'b1;
					mio_en = 1'b1; //reading from memory here
				end
			s_35 : 
				begin 
					gate_mdr = 1'b1;
					ld_ir = 1'b1;
				end
			pause_ir1: ld_led = 1'b1; 
			pause_ir2: ld_led = 1'b1; 

			s_32 : 
				begin
					ld_ben = 1'b1;
				end
			s_1 : // DR <- SR1 + OP2, set cc
				begin
					drmux = 1'b0;
					sr1mux = 1'b1;
					sr2mux = ir[5];
					aluk = 2'b00;
					gate_alu = 1'b1;
					ld_reg = 1'b1;
					ld_cc = 1'b1;
				end
			s_5 : // DR <- SR1 & OP2, set cc
				begin
					drmux = 1'b0;
					sr1mux = 1'b1;
					sr2mux = ir[5];
					aluk = 2'b01;
					gate_alu = 1'b1;
					ld_reg = 1'b1;
					ld_cc = 1'b1;
				end	
			s_9 :  // DR <- NOT(SR), set cc
				begin
					sr1mux = 1'b1;
					aluk = 2'b10;
					gate_alu = 1'b1;
					drmux = 1'b0;
					ld_reg = 1'b1;
					ld_cc = 1'b1;
				end	
			s_6 : // MAR <- B + off6
				begin
					sr1mux = 1'b1;
					addr1mux = 1'b1;
					addr2mux = 2'b01;
					gate_marmux = 1'b1;
					ld_mar = 1'b1;
				end	
			s_25_1, s_25_2, s_25_3 : // MDR <- M[MAR] (R state x3)
				begin
					ld_mdr = 1'b1;
					mem_mem_ena = 1'b1;
					mio_en = 1'b1; //read from memory
				end	
			s_27 : 
				begin
					drmux = 1'b0;
					ld_reg = 1'b1;
					ld_cc = 1'b1;
					gate_mdr = 1'b1;

				end	
			s_7 : // MAR <- B + off6 (again)
				begin
					sr1mux = 1'b1;
					addr1mux = 1'b1;
					addr2mux = 2'b01;
					gate_marmux = 1'b1;
					ld_mar = 1'b1;
				end	
			s_23 : // MDR <- SR
				begin
					sr1mux = 1'b0;
					aluk = 2'b11;
					gate_alu = 1'b1;
					mio_en = 1'b0;
					ld_mdr = 1'b1;
				end	
			s_16_1, s_16_2, s_16_3 : // M[MAR] <- MDR (R state x3)
				begin
					mem_mem_ena = 1'b1;
					mem_wr_ena = 1'b1;
					mio_en = 1'b1;
				end	
			s_0 : //if(BEN) {pc <- pc + pc(sextoff(9))}
				begin
					// only checks value of BEN, no control signals asserted here
				end	
			s_22 :  // pc <- pc + off9
				begin
					ld_pc = 1'b1;
					pcmux = 2'b10;
					addr1mux = 1'b0;
					addr2mux = 2'b10;
				end	
			s_12 : 
				begin
					sr1mux = 1'b1;
					aluk = 2'b11;
					gate_alu = 1'b1;
					pcmux = 2'b01;
					ld_pc = 1'b1;
				end	
			s_4 : 
				begin
					gate_pc = 1'b1;
					drmux = 1'b1;
					ld_reg = 1'b1;
				end	
			s_21 : 
				begin
					addr1mux = 1'b0;
					addr2mux = 2'b11;
					pcmux = 2'b10;
					ld_pc = 1'b1;
				end	
			default : ;
		endcase
	end 


	always_comb
	begin
		// default next state is staying at current state
		state_nxt = state;

		unique case (state)
			halted : 
				if (run_i) 
					state_nxt = s_18;
			s_18 : 
				state_nxt = s_33_1; //notice that we usually have 'r' here, but you will need to add extra states instead 
			s_33_1 :                 //e.g. s_33_2, etc. how many? as a hint, note that the bram is synchronous, in addition, 
				state_nxt = s_33_2;   //it has an additional output register. 
			s_33_2 :
				state_nxt = s_33_3;
			s_33_3 : 
				state_nxt = s_35;
			s_35 : 
				state_nxt = s_32;
			s_32 : begin
					unique case(opcode) 
						4'b0001: state_nxt = s_1;
						4'b0101: state_nxt = s_5;
						4'b1001: state_nxt = s_9;
						4'b0110: state_nxt = s_6;
						4'b0111: state_nxt = s_7;
						4'b0100: state_nxt = s_4;
						4'b1100: state_nxt = s_12;
						4'b0000: state_nxt = s_0;
						4'b1101: state_nxt = pause_ir1;
						default: state_nxt = s_18;
					endcase
			end
			s_1 : 
				state_nxt = s_18;
			s_5 : 
				state_nxt = s_18;
			s_9 : 
				state_nxt = s_18;
			s_6 : 
				state_nxt = s_25_1;
			s_25_1 : 
				state_nxt = s_25_2;
			s_25_2 : 
				state_nxt = s_25_3;
			s_25_3 : 
				state_nxt = s_27;
			s_27 : 
				state_nxt = s_18;
			s_7 : 
				state_nxt = s_23;
			s_23 : 
				state_nxt = s_16_1;
			s_16_1 : 
				state_nxt = s_16_2;
			s_16_2 : 
				state_nxt = s_16_3;
			s_16_3 : 
				state_nxt = s_18;
			s_4 : 
				state_nxt = s_21;
			s_21 : 
				state_nxt = s_18;
			s_12 : 
				state_nxt = s_18;
			s_0 : begin
				if (ben) state_nxt = s_22;
				else state_nxt = s_18;
			end
			s_22 : 
				state_nxt = s_18;

			
			
			// Pause until the continue button is pressed and released.
			pause_ir1 : 
				if (continue_i) 
					state_nxt = pause_ir2;
			pause_ir2 : 
				if (~continue_i)
					state_nxt = s_18;
			default :;
		endcase
	end
	
endmodule
