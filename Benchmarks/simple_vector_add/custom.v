/* Copyright 2021 Philippos Papaphilippou

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

`define c3_pipe_cycles 1


// Template for custom SIMD instruction (modified to include ADD)

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
	output [32-1:0] out_data;
	output reg [`VLEN-1:0] out_vdata1; 
	output [`VLEN-1:0] out_vdata2;
	
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
	integer i;
	always @(posedge clk) begin
		for (i=0; i<8; i=i+1) begin
			if (in_v) out_vdata1[32*(i+1)-1-:32] <= in_vdata1[32*(i+1)-1-:32] + in_vdata2[32*(i+1)-1-:32];				
		end	
	end	
		
	assign out_data=0;
	//assign out_vdata1=0;
	assign out_vdata2=0;
	
endmodule // C3_custom_SIMD_instruction

