/*  Copyright 2021-2024 Philippos Papaphilippou

	You are free to use, learn from, modify and distribute this creative work under 
	  the following conditions:
	1. No code, text, or other elements of this work can be used as an input to models
	  for the purposes of training. Generative A.I. and language models are prohibited
	  from using this work. These do not include search engines and related tools whose
	  main purpose is to index and appropriately point to the original source and author.
	2. It comes under no warranties.
	3. Any modification to the code shall be made available in the style of GNU General
	  Public License v2.0 (GPL-2.0), but published under the same license (not GPL-2.0,
	  and clause 7 still refers to the original copyright holder).
	4. A proper attribution of the author (copyright holder) is required when the work 
	  is used. (If applicable, it would be appreciated to cite the related academic
	  publication that introduced the work.)
	5. It cannot be used for commercial purposes unless specific permission is given by
	  the author. 
	6. A redistribution shall include this license in its entirety.
	7. The author has the right to change this license for future versions of this work,
	  as well as to update and clarify the author's original intentions of the current
	  version, such as with regard to what is considered "fair use" by the author for
	  future entities and technologies.  
*/

`define c3_pipe_cycles 5


// Template for custom SIMD instruction

module C3_custom_SIMD_instruction (clk, reset, 
	in_v, rd, vrd1, vrd2, 
		in_data, in_vdata1, in_vdata2, 
	out_v, out_rd, out_vrd1, out_vrd2, 
		out_data, out_vdata1, out_vdata2);
	input clk, reset;
	
	input in_v;
	input [4:0] rd;
	input [2:0] vrd1, vrd2;			
	input [32-1:0] in_data;
	input [`VLEN-1:0] in_vdata1, in_vdata2;	
	
	output out_v;
	output [4:0] out_rd;
	output [2:0] out_vrd1, out_vrd2;	
	output  [32-1:0] out_data;
	output [`VLEN-1:0] out_vdata1, out_vdata2;
	
	reg [`c3_pipe_cycles-1:0] valid_sr;
	reg [5*`c3_pipe_cycles-1:0] rd_sr; 
	reg [3*`c3_pipe_cycles-1:0] vrd1_sr, vrd2_sr;
	
	always @(posedge clk) begin
		if (reset) begin
			valid_sr<=0; rd_sr<=0; vrd1_sr<=0; vrd2_sr<=0;
		end else begin
			valid_sr<= (valid_sr<<1)|in_v;			
			  rd_sr <= (   rd_sr<<5)| rd;
			vrd1_sr <= ( vrd1_sr<<3)|vrd1; 
			vrd2_sr <= ( vrd2_sr<<3)|vrd2;
		end
	end
	assign out_v   =valid_sr[  `c3_pipe_cycles-1];
	assign out_rd  =   rd_sr[5*`c3_pipe_cycles-1-:5];
	assign out_vrd1= vrd1_sr[3*`c3_pipe_cycles-1-:3]; 
	assign out_vrd2= vrd2_sr[3*`c3_pipe_cycles-1-:3];
	
	////// USER CODE HERE //////	
	assign out_data=0;
	assign out_vdata1=0;
	assign out_vdata2=0;
endmodule // C3_custom_SIMD_instruction


// Merger instruction implementation

module Merger2x8x32bit (clk, reset, rd, vrd1, vrd2, in_v, in8A, in8B, out_v, out8A, out8B, out_rd, out_vrd1, out_vrd2, next_source_v, next_source, not_accepting);
	input clk, reset;
	
	input [4:0] rd;
	input [2:0] vrd1;
	input [2:0] vrd2;		
	
	input in_v;
	input [256-1:0] in8A;
	input [256-1:0] in8B;
	
	output out_v;
	output [256-1:0] out8A;
	output [256-1:0] out8B;
	
	output reg [4:0] out_rd;
	output [2:0] out_vrd1;
	output [2:0] out_vrd2;	
	
	output reg next_source_v;
	output reg next_source;
	
	output reg not_accepting;
	
	wire [31:0] network [79:0];
	
	reg [4+1-1:0] valid_sr;
	reg [3*(4+1)-1:0] vrd1_sr; reg [3*(4+1)-1:0] vrd2_sr;
	
	wire direction; assign direction=in8A[31:0]<in8B[31:0];
	
	reg [31:0] first_half [7:0];
	reg [31:0] second_half [7:0];
	
	integer k; reg started;
	always @(posedge clk) begin
		if (reset) begin
			valid_sr<=0; vrd1_sr<=0; vrd2_sr<=0;
			next_source_v<=0;
			not_accepting<=0;
			started<=0;
		end else begin
		
			// Shift register for output operand names and valid bit
			valid_sr<=(valid_sr<<1)|in_v;

			vrd1_sr<=(vrd1_sr<<3)|vrd1; vrd2_sr<=(vrd2_sr<<3)|vrd2;
			
			next_source	<= !direction;
			next_source_v<=in_v;
			out_rd<=rd;	
			
			// Selector logic (chose the next source and process the correct vector)			
			if ((direction==1) || (!started))
				for (k=0; k<8; k=k+1) first_half[k]<=in8A[32*(k+1)-1-:32];
			else
				for (k=0; k<8; k=k+1) first_half[k]<=in8B[32*(k+1)-1-:32];
				
			if (in_v) begin
				not_accepting<=1;
				started<=1;
				if (!started) 
					for (k=0; k<8; k=k+1) second_half[k]<=in8B[32*(k+1)-1-:32];
			end
			
			// Used to reset its state
			if (in_v && (rd==0)) started<=0; 
			
			// On valid output declare that it can accept next vectors (not pipelined)
			if (out_v) begin
				not_accepting<=0;
				
				// Move the lower 8 to the input of the bitonic merger for the iteration
				for (k=0; k<8; k=k+1) second_half[k]<=network[64+k+8];
			end
		end
	end 
	assign out_v=valid_sr[5-1];

	assign out_vrd1=vrd1_sr[3*5-1-:3]; assign out_vrd2=vrd2_sr[3*5-1-:3];
	
	genvar i;
	for (i=0; i<8; i=i+1) begin assign network[i]=first_half[i]; end
	for (i=0; i<8; i=i+1) begin assign network[8+i]=second_half[i]; end
	
	// Bitonic merger of size 16 (merging 2*8)
	
	CAS_unit casm0(clk, network[0], network[8], network[16], network[24]);
	CAS_unit casm1(clk, network[1], network[9], network[17], network[25]);
	CAS_unit casm2(clk, network[2], network[10], network[18], network[26]);
	CAS_unit casm3(clk, network[3], network[11], network[19], network[27]);
	CAS_unit casm4(clk, network[4], network[12], network[20], network[28]);
	CAS_unit casm5(clk, network[5], network[13], network[21], network[29]);
	CAS_unit casm6(clk, network[6], network[14], network[22], network[30]);
	CAS_unit casm7(clk, network[7], network[15], network[23], network[31]);

	SR_module smodule8(clk, network[16], network[32]);
	SR_module smodule9(clk, network[17], network[33]);
	SR_module smodule10(clk, network[18], network[34]);
	SR_module smodule11(clk, network[19], network[35]);
	CAS_unit casm12(clk, network[20], network[24], network[36], network[40]);
	CAS_unit casm13(clk, network[21], network[25], network[37], network[41]);
	CAS_unit casm14(clk, network[22], network[26], network[38], network[42]);
	CAS_unit casm15(clk, network[23], network[27], network[39], network[43]);
	SR_module smodule16(clk, network[28], network[44]);
	SR_module smodule17(clk, network[29], network[45]);
	SR_module smodule18(clk, network[30], network[46]);
	SR_module smodule19(clk, network[31], network[47]);

	SR_module smodule20(clk, network[32], network[48]);
	SR_module smodule21(clk, network[33], network[49]);
	CAS_unit casm22(clk, network[34], network[36], network[50], network[52]);
	CAS_unit casm23(clk, network[35], network[37], network[51], network[53]);
	CAS_unit casm24(clk, network[38], network[40], network[54], network[56]);
	CAS_unit casm25(clk, network[39], network[41], network[55], network[57]);
	CAS_unit casm26(clk, network[42], network[44], network[58], network[60]);
	CAS_unit casm27(clk, network[43], network[45], network[59], network[61]);
	SR_module smodule28(clk, network[46], network[62]);
	SR_module smodule29(clk, network[47], network[63]);

	SR_module smodule30(clk, network[48], network[64]);
	CAS_unit casm31(clk, network[49], network[50], network[65], network[66]);
	CAS_unit casm32(clk, network[51], network[52], network[67], network[68]);
	CAS_unit casm33(clk, network[53], network[54], network[69], network[70]);
	CAS_unit casm34(clk, network[55], network[56], network[71], network[72]);
	CAS_unit casm35(clk, network[57], network[58], network[73], network[74]);
	CAS_unit casm36(clk, network[59], network[60], network[75], network[76]);
	CAS_unit casm37(clk, network[61], network[62], network[77], network[78]);
	SR_module smodule38(clk, network[63], network[79]);
	
	// Export the output of the last layer of the CAS network
	for (i=0; i<8; i=i+1) begin assign out8A[32*(i+1)-1-:32]=network[64+i]; end
	for (i=8; i<16; i=i+1) begin assign out8B[32*(i-8+1)-1-:32]=network[64+i]; end
	
	initial begin
		if (`DEB)$dumpfile("gtkw_custom2.vcd");
		if (`DEB)$dumpvars(0, clk, reset, rd, vrd1, vrd2, in_v, in8A, in8B, out_v, out8A, out8B, out_rd, out_vrd1, out_vrd2, next_source_v, next_source, not_accepting,first_half[0],
		second_half[0],second_half[1],second_half[2],second_half[3],
		second_half[4],second_half[5],second_half[6],second_half[7]
		);
	end
endmodule // Merger2x8x32bit

// Sorts a single vector of 8 32-bit values using odd-even merge sort
module Sorter1x8x32bit (clk, reset, vrd, in_v, in8, out_v, out8, out_vrd);
	input clk, reset;
	
	input [2:0] vrd;
	
	input in_v;
	input [256-1:0] in8;
	
	output out_v;
	output [256-1:0] out8;
	
	output [2:0] out_vrd;
	
	wire [31:0] network [55:0];
	
	reg [6-1:0] valid_sr; reg [3*6-1:0] vrd_sr;
	
	// Shift registers for output operand names and ready bit
	always @(posedge clk) begin
		if (reset) begin
			valid_sr<=0; vrd_sr<=0;
		end else begin
			valid_sr<=(valid_sr<<1)|in_v;
			vrd_sr<=(vrd_sr<<3)|vrd; 	
		end
	end
	assign out_v=valid_sr[6-1];
	assign out_vrd=vrd_sr[3*6-1-:3];
	
	genvar i;
	for (i=0; i<8; i=i+1) begin assign network[i]=in8[32*(i+1)-1-:32]; end
	
	// CAS network (Batcher's odd-even mergesort)
	
	CAS_unit casm0(clk, network[0], network[1], network[8], network[9]);
	CAS_unit casm1(clk, network[2], network[3], network[10], network[11]);
	CAS_unit casm2(clk, network[4], network[5], network[12], network[13]);
	CAS_unit casm3(clk, network[6], network[7], network[14], network[15]);

	CAS_unit casm4(clk, network[8], network[10], network[16], network[18]);
	CAS_unit casm5(clk, network[9], network[11], network[17], network[19]);
	CAS_unit casm6(clk, network[12], network[14], network[20], network[22]);
	CAS_unit casm7(clk, network[13], network[15], network[21], network[23]);

	SR_module smodule8(clk, network[16], network[24]);
	CAS_unit casm9(clk, network[17], network[18], network[25], network[26]);
	SR_module smodule10(clk, network[19], network[27]);
	SR_module smodule11(clk, network[20], network[28]);
	CAS_unit casm12(clk, network[21], network[22], network[29], network[30]);
	SR_module smodule13(clk, network[23], network[31]);

	CAS_unit casm14(clk, network[24], network[28], network[32], network[36]);
	CAS_unit casm15(clk, network[25], network[29], network[33], network[37]);
	CAS_unit casm16(clk, network[26], network[30], network[34], network[38]);
	CAS_unit casm17(clk, network[27], network[31], network[35], network[39]);

	SR_module smodule18(clk, network[32], network[40]);
	SR_module smodule19(clk, network[33], network[41]);
	CAS_unit casm20(clk, network[34], network[36], network[42], network[44]);
	CAS_unit casm21(clk, network[35], network[37], network[43], network[45]);
	SR_module smodule22(clk, network[38], network[46]);
	SR_module smodule23(clk, network[39], network[47]);

	SR_module smodule24(clk, network[40], network[48]);
	CAS_unit casm25(clk, network[41], network[42], network[49], network[50]);
	CAS_unit casm26(clk, network[43], network[44], network[51], network[52]);
	CAS_unit casm27(clk, network[45], network[46], network[53], network[54]);
	SR_module smodule28(clk, network[47], network[55]);
	
	// Export the output of the last layer of the CAS network
	for (i=0; i<8; i=i+1) begin assign out8[32*(i+1)-1-:32]=network[48+i]; end
	
	initial begin
		if (`DEB)$dumpfile("gtkw_custom2.vcd");
		if (`DEB)$dumpvars(0, clk, reset, vrd, in_v, in8, out_v, out8, out_vrd);
	end
endmodule // Sorter1x8x32bit


// Compare-and-swap (CAS) unit		
module CAS_unit(clk, inA, inB, outA, outB);
	input clk;
	input [31:0] inA;
	input [31:0] inB;
	output reg [31:0] outA;
	output reg [31:0] outB;
	
	always @(posedge clk) begin
		if (inA<inB) begin
			outA<=inA; outB<=inB;
		end else begin
			outB<=inA; outA<=inB;
		end
	end
endmodule //CAS_unit


// Shift register for empty places in the CAS networks or prefix sum
module SR_module(clk, din, dout);
	input clk;
	input      [31:0] din;
	output reg [31:0] dout;
	
	always @(posedge clk) dout<=din;
endmodule //SR_module


// Prefic sum implementation (see paper for more details on the topology)
module PrefixSum1x8x32bit (clk, reset, vrd, in_v, in8, out_v, out8, out_vrd);
	input clk, reset;
	
	input [2:0] vrd;
	
	input in_v;
	input [256-1:0] in8;
	
	output out_v;
	output [256-1:0] out8;
	
	output [2:0] out_vrd;
	
	wire [31:0] network [39:0];
	
	reg [4-1:0] valid_sr; reg [3*4-1:0] vrd_sr;
	
	// Shift registers for the output operands and ready bit
	always @(posedge clk) begin
		if (reset) begin
			valid_sr<=0; vrd_sr<=0;
		end else begin
			valid_sr<=(valid_sr<<1)|in_v;
			vrd_sr<=(vrd_sr<<3)|vrd; 	
		end
	end
	assign out_v=valid_sr[4-1];
	assign out_vrd=vrd_sr[3*4-1-:3];
	wire zero_sum; assign zero_sum = reset|(valid_sr[2] && (vrd_sr[3*3-1-:3]==0));
	
	genvar i;
	for (i=0; i<8; i=i+1) begin assign network[i]=in8[32*(i+1)-1-:32]; end
	
	/*---- Prefix sum (P=8) ----*/
	SR_module addm0(clk,                           network[0], network[8]);
	ADD_module addm1(clk, reset, in_v, network[0], network[1], network[9]);
	ADD_module addm2(clk, reset, in_v, network[1], network[2], network[10]);
	ADD_module addm3(clk, reset, in_v, network[2], network[3], network[11]);
	ADD_module addm4(clk, reset, in_v, network[3], network[4], network[12]);
	ADD_module addm5(clk, reset, in_v, network[4], network[5], network[13]);
	ADD_module addm6(clk, reset, in_v, network[5], network[6], network[14]);
	ADD_module addm7(clk, reset, in_v, network[6], network[7], network[15]);

	SR_module addm8(clk,                                  network[8], network[16]);
	SR_module addm9(clk,                                  network[9], network[17]);
	ADD_module addm10(clk, reset, valid_sr[0], network[8], network[10], network[18]);
	ADD_module addm11(clk, reset, valid_sr[0], network[9], network[11], network[19]);
	ADD_module addm12(clk, reset, valid_sr[0], network[10], network[12], network[20]);
	ADD_module addm13(clk, reset, valid_sr[0], network[11], network[13], network[21]);
	ADD_module addm14(clk, reset, valid_sr[0], network[12], network[14], network[22]);
	ADD_module addm15(clk, reset, valid_sr[0], network[13], network[15], network[23]);

	SR_module addm16(clk,                                  network[16], network[24]);
	SR_module addm17(clk,                                  network[17], network[25]);
	SR_module addm18(clk,                                  network[18], network[26]);
	SR_module addm19(clk,                                  network[19], network[27]);
	ADD_module addm20(clk, reset, valid_sr[1], network[16], network[20], network[28]);
	ADD_module addm21(clk, reset, valid_sr[1], network[17], network[21], network[29]);
	ADD_module addm22(clk, reset, valid_sr[1], network[18], network[22], network[30]);
	ADD_module addm23(clk, reset, valid_sr[1], network[19], network[23], network[31]);


	/*---- Additional step to add and keep the sum of last batch ----*/
	ADD_module addm24(clk, zero_sum, valid_sr[2], network[24], network[39], network[32]);
	ADD_module addm25(clk, zero_sum, valid_sr[2], network[25], network[39], network[33]);
	ADD_module addm26(clk, zero_sum, valid_sr[2], network[26], network[39], network[34]);
	ADD_module addm27(clk, zero_sum, valid_sr[2], network[27], network[39], network[35]);
	ADD_module addm28(clk, zero_sum, valid_sr[2], network[28], network[39], network[36]);
	ADD_module addm29(clk, zero_sum, valid_sr[2], network[29], network[39], network[37]);
	ADD_module addm30(clk, zero_sum, valid_sr[2], network[30], network[39], network[38]);
	ADD_module addm31(clk, zero_sum, valid_sr[2], network[31], network[39], network[39]);
	
	for (i=0; i<8; i=i+1) begin assign out8[32*(i+1)-1-:32]=network[32+i]; end
	
	initial begin
		if (`DEB)$dumpfile("gtkw_custom2.vcd");
		if (`DEB)$dumpvars(0, clk, reset, vrd, in_v, in8, out_v, out8, out_vrd);
	end
endmodule // PrefixSum1x8x32bit


// Adder module used by the prefix sum custom SIMD instruction		
module ADD_module(clk, reset, valid, data_inA, data_inB, data_out);

	input clk, reset, valid;

	input[32-1:0] data_inA;
	input[32-1:0] data_inB;		
	output reg [32-1:0] data_out;	
	
	always @(posedge clk) begin		
		if (reset) begin
			data_out<=0; 
		end else begin			
			if (valid) data_out <= data_inA + data_inB;
		end
	end			
endmodule //ADD_module


