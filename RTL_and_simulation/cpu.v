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

//`define XLEN 32 // (not yet other than 32)

`define IADDR_bits 21
`define DADDR_bits 30 // >= IADDR_bits

`define VLEN 256
`define VLEN_Log2 $clog2(`VLEN)

`define NumVregisters 4 // (-1 for register 0, up to 8 -1 registers)

`define Rtype 0 // No immediate
`define Itype 1
`define Stype 2
`define Btype 3
`define Utype 4 // 20-bit immediate
`define Jtype 5

// Instruction decode is done asynchronusly as it happens in the same cycle
module IDecoder(instr, iformat, rs1, rs2, rd, immediate, alui_en, auipc_en, load_en, absolute_pc, m_inst, counters, simd_inst, c1_en, c2_en, c3_en);
	input [31:0] instr;
	output reg [2:0] iformat;
	output [4:0] rs1;
	output [4:0] rs2;
	output [4:0] rd;
	output reg [31:0] immediate;
	output reg alui_en;
	output reg auipc_en;
	output reg load_en;
	output reg absolute_pc;
	output reg m_inst;
	output reg counters;
	output reg simd_inst;
	output reg c1_en;
	output reg c2_en;
	output reg c3_en;	
	
	assign rs1 = instr[19:15];
	assign rs2 = instr[24:20];
	assign rd  = instr[11: 7];
	
	always @(*) begin
		case (instr[6:2])
			5'h18: iformat = `Btype; // beq, bne, blt, bge, bltu, bgeu,
			5'h19: iformat = `Itype; // jalr, *
			5'h1b: iformat = `Jtype; // jal,  *
			5'h0d: iformat = `Utype; // lui,  *
			5'h05: iformat = `Utype; // auipc,*
			5'h04: iformat = `Itype; // addi,     slli, slti, sltiu, xori, srli, srai, ori, andi,
			5'h0c: iformat = `Rtype; // add, sub, sll,  slt,  sltu,  xor,  srl,  sra,  or,  and,
									 // mul, mulh, mulhsu, mulhu, div, divu, rem, remu
			5'h00: iformat = `Itype; // lb, lh, lw, lbu, lhu,
			5'h08: iformat = `Stype; // sb, sh, sw,
			5'h03: iformat = `Itype; // fence, fence.i *
			5'h1c: iformat = `Itype; // CSR (rdcycle, rdtime, rdinstret, rdcycleh, rdtimeh, rdinstreth)
			5'h02: iformat = `Rtype; // Custom instruction 0 (c0_lv, c0_sv)
			5'h0A: iformat = `Itype; // Custom instruction 1 (c1 (for c1_merge in the example))	
			5'h16: iformat = `Itype; // Custom instruction 2 (c2 (for c2_sort or c2_prefix in the example))	
			5'h1E: iformat = `Itype; // Custom instruction 3 (c3)		

			default begin 
				iformat =`Rtype; 
			end
		endcase

		
		
		case (iformat)
			//`Rtype:
			`Itype: immediate = {{21{instr[31]}}, instr[30:25], instr[24:21], instr[20]};
			`Stype: immediate = {{21{instr[31]}}, instr[30:25], instr[11:8], instr[7]};
			`Btype: immediate = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
			`Utype: immediate = {instr[31], instr[30:20],instr[19:12], 12'b0};
			`Jtype: immediate = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0};
			default: immediate = 0;
		endcase
		
		alui_en=0; auipc_en=0; load_en=0; absolute_pc=0; m_inst=0; counters=0;
		simd_inst=0; c1_en=0; c2_en=0; c3_en=0;
		case (instr[6:2])
			5'h00: load_en=1;
			5'h05: auipc_en=1; // auipc,
			5'h19: begin alui_en=1; absolute_pc=1; end
			5'h1b: begin                           end// jalr,
			5'h04: alui_en=1; // addi,     slli, slti, sltiu, xori, srli, srai, ori, andi,
			5'h0c: begin 
			  alui_en=!instr[25];  // add, sub, sll,  slt,  sltu,  xor,  srl,  sra,  or,  and,		
				m_inst=instr[25]; // mul, mulh, mulhsu, mulhu, div, divu, rem, remu
			end
			5'h1c: counters=1;
			5'h02: begin load_en=instr[14:12]==0; simd_inst=1; end
			5'h0A: begin c1_en=1; simd_inst=1; end
			5'h16: begin c2_en=1; simd_inst=1; end	
			5'h1E: begin c3_en=1; simd_inst=1; end			
			default:; 
		endcase
	end 	
endmodule // IDecoder

// Integer ALU for the base registers
module ALUint(data1, data2, func, result);
	input [31:0] data1;
	input [31:0] data2;
	input [3:0] func;
	output reg [31:0] result;
	
	wire[32:0] sub;  assign sub = data1-data2;
	wire sign_swap = data1[31]!=data2[31];
	
	always @(*) begin
		if (`DEB)$display("%h func(%h) %h", data1, func, data2);
		case (func[2:0]) 
			3'h0: begin 
				if (func[3]==0)
					result = data1 + data2; // add(i)
				else 
					result = sub; // sub (func 0 with instr[30]==1 & not imm) (subi not available)
				end
			3'h1: result = data1 << data2[4:0];// sll(i)
			3'h2: result = (sub[32]==1)^(sign_swap);// ($signed(data1) < $signed(data2)); // slt(i)
			3'h3: result = (sub[32]==1); // slt(i)u
			3'h4: result = data1 ^  data2; // xor(i)
			3'h5: begin
					if (func[3]==0) 
						result = data1 >> data2[4:0];// srl(i) 
					else
						result = $signed(data1) >>> data2[4:0];// sra(i) (func 5 with instr[30]==1)
				  end
			3'h6: result = data1 | data2; // or(i)
			3'h7: result = data1 & data2;// and(i)	
			default: result=0;	
		endcase
	end
endmodule // ALUint

// ALU for the "M" extension (behaviourial)
module ALUintM(clk, reset, valid, rdin, data1, data2, func, result, rd, ready, accepting);
	input clk, reset, valid;
	input [4:0] rdin;
	input [31:0] data1;
	input [31:0] data2;
	input [3:0] func;	
	output reg [31:0] result;
	output reg [4:0] rd;
	output reg ready;
	output reg accepting;		
	
	reg [63:0] num1; reg [63:0] num2;
	always @(*) begin
		case (func) 
            3'h0: begin num1 ={32'b0,data1}; num2 = {32'b0,data2};  end // mul
            3'h1: begin num1 ={{32{data1[31]}},data1}; num2 = {{32{data2[31]}},data2}; end // mulh
            3'h2: begin num1 ={{32{data1[31]}},data1}; num2 = {32'b0,data2}; end // mulhu
            3'h3: begin num1 ={32'b0,data1}; num2 = {32'b0,data2}; end // mulhsu
			default: begin num1 = data1; num2 = data2; end
		endcase
	end
	
	reg [63:0] product;	
	reg [1:0] clk2;
	reg [2:0] pend_f;
	reg [63:0] data1s; reg [63:0] data2s; reg pend; reg pend2;
	always @(posedge clk) begin
	   if (reset) begin 
	       clk2<=0;
	       pend<=0;
	       pend2=0;
	       pend_f<=0;
	       accepting<=1;
	   end else begin 
	       clk2<=clk2+1;       
	       if (valid) begin 
	       	 if (`DEB)$display ("ALUintM %h %h",num1,num2,data1,data2 );
	       	 data1s<=num1;   
	      	 data2s<=num2;
	      	 pend2=valid;
	      	 rd<=rdin;
	      	 pend_f<=func;
	      	 accepting<=0;
	      end    
	      
	      if (pend2 && (clk2==2'b01)) begin
	      	pend<=1;
	      	pend2=0;
	      end	
	      	
	      ready<=0;  
	      if (clk2==2'b01 && pend) begin
	      	 pend<=0;
	      	 ready<=1; 	
	      	 accepting<=1;      	 
	      end    
	      
	   end
	end
	
	wire lc = (clk2==2'b11);
	always @(posedge /*clk2[1]*/lc) begin	
		
		product = data1s * data2s;
		case (pend_f) 
			3'h0: result <= product[31:0]; // mul 
			3'h1: result <= product[63:32]; // mulh
			3'h2: result <= product[63:32]; // mulhu
			3'h3: result <= product[63:32]; // mulhsu
			3'h4: result <= $signed(data1s[31:0])/$signed(data2s[31:0]); // div
			3'h5: result <= data1s[31:0]/data2s[31:0]; // divu
			3'h6: result <= $signed(data1s[31:0])%$signed(data2s[31:0]); // rem
			3'h7: result <= data1s[31:0]%data2s[31:0]; // remu
			default: result<=0;	
		endcase
		if (`DEB)if (valid)$display("ALUM %d %d = %d, func %d", data1, data2, result, func);
	end
endmodule // ALUintM

// Separate ALU for the branch operations
module ALUbranch(data1, data2, func, result);
	input [32:0] data1;
	input [32:0] data2;
	input [2:0] func;
	output reg result;
	
	wire[32:0] sub;  assign sub = data1-data2;
	wire sign_swap = data1[31]!=data2[31];
		
	always @(*) begin
		case (func) 
			3'h0: result = sub==0; // beq
			3'h1: result = sub!=0; // bne					
			3'h4: begin 
				result = (sub[32]==1)^(sign_swap); 
				if (`DEB)$display("blt> %h %h %h", data1, data2, result); 
			end // blt
			3'h5: begin 
				result = (sub[32]==0)^(sign_swap); 
				if (`DEB)$display("bge> %h %h %h", data1, data2, result); 
			end // bge
			3'h6: result = sub[32]==1; // bltu
			3'h7:begin 
				result = sub[32]==0; 
				if (`DEB) $display("bgeu> %h %h %h", data1, data2, result); 
			end // bgeu	
			default: result = 0; 	
		endcase
	end
endmodule // ALUbranch

// Asynchronus PC logic (so that the next PC is available to IL1 beforehand, for no delay on IL1 hits)
module PClogic (clk, reset, next_direction, next_step, PC, PCnext);
	input clk, reset;
	input [1:0] next_direction;
	input [`IADDR_bits-1:0] next_step; // sign-extended
	input [`IADDR_bits-1:0] PC;
	output reg [`IADDR_bits-1:0] PCnext;
	
	always @(*) begin
		begin
			case (next_direction)
				2'h0: PCnext = PC;
				2'h1: PCnext = PC + 4; 
				2'h2: PCnext = PC + next_step;
				2'h3: PCnext = next_step;
			endcase 			
		end		
	end	
endmodule // PClogic


module Core (clk, reset, cycles, 
		addrA, dinA, readyI, StartAddress, StackPointer,
		addrB, dinB, doutB, enB, weB, readyB, accepting,
		debug
		);
		
	input clk, reset; 

	output [31:0] cycles; // carry cycle count only for debugging, hence the 32-bit limit
	
	output [`IADDR_bits-1:0] addrA;
    input wire [32-1:0] dinA;
    input wire readyI;
    
    input wire [`IADDR_bits-1:0] StartAddress;
    input wire [`DADDR_bits-1:0] StackPointer;
    
    output reg [`DADDR_bits-1:0] addrB;
    input wire [`VLEN-1:0] dinB;
    output reg [`VLEN-1:0] doutB;
    output reg enB;

    output reg [`VLEN/8-1:0] weB;

    input readyB; input accepting;    
	output debug;
	
	reg [48-1:0] cycle_counter; reg [48-1:0] instr_counter;
	
	reg [`IADDR_bits-1:0] PC; wire [`IADDR_bits-1:0] PCnext; wire [31:0] instr; reg halt;
	reg [31:0] reg_file [31:0]; assign debug=halt;//PC;
	wire [1:0] next_direction;
	wire [`IADDR_bits-1:0] next_step; 	
	
	wire [2:0] func3; assign func3=instr[14:12];
	
	PClogic pcl(clk, reset, next_direction, next_step, PC, PCnext);
	
	assign addrA = PCnext;
	assign instr = dinA; 
			
	wire  alui_enable, auipc_enable, load_enable, absolute_pc, m_inst;	
	wire [2:0] iformat; wire [31:0] immediate;
	wire [4:0] rs1; wire [4:0] rs2; wire [4:0] rd; wire counters;
	wire simd_inst; wire c1_en, c2_en, c3_en;
	
	wire [`DADDR_bits-1:0] daddr; assign daddr=reg_file[rs1]+(simd_inst?reg_file[rs2]:immediate);
	
	IDecoder ide (instr, iformat, rs1, rs2, rd, immediate, alui_enable, auipc_enable, load_enable, absolute_pc, m_inst, counters, simd_inst, c1_en, c2_en, c3_en);	
	
	// Logic for deciding next PC behaviour, according to the instruction type (iformat), 
	// ALU branch result (branch_take), and when there is a stall (halt) etc.
	wire branch_take; wire [31:0] alu_dst;	
	wire dir_bit1; assign dir_bit1 = absolute_pc || ((iformat==`Jtype) || (branch_take && (iformat==`Btype)));
	wire dir_bit0; assign dir_bit0 = (iformat!=`Jtype) && !(branch_take && (iformat==`Btype));
	assign next_direction = {dir_bit1, dir_bit0}&{!(halt|reset), !(halt|reset)};	
	assign next_step= absolute_pc?{daddr[`DADDR_bits-1:1],1'b0}:immediate;
	
	wire [`IADDR_bits-1:0] auipc; assign auipc = PC+immediate;
	wire [`IADDR_bits-1:0] pc4; assign pc4=PC+4;
	
	// Select the appropriate operands for ALUint, such as according to if it adds the immediate field
	wire [31:0] alu_rs1; assign alu_rs1 = reg_file[rs1];
	wire [31:0] alu_rs2; assign alu_rs2 = (iformat==`Itype || iformat==`Stype)?immediate:reg_file[rs2];
	wire [3:0] alu_func; assign alu_func = {instr[30]&&!(iformat==`Itype&&func3==0),func3};
	
	ALUint    alu0 (alu_rs1, alu_rs2, alu_func, alu_dst);		
	ALUbranch alu1 (alu_rs1, alu_rs2, func3, branch_take);
	
	// Separate ALU for the "M" instruction
	wire [4:0] m_rd; wire m_ready; wire [31:0] m_res; wire m_acc;
	ALUintM   alu2 (clk, reset, m_inst&!halt, rd, alu_rs1, alu_rs2, alu_func, m_res, m_rd, m_ready, m_acc);
	
	integer i;	
	reg was_en2, readok;
	
	// 4 outstanding reads (must be in order) (but not very pipelined at the moment)
	reg [1:0] read_rq_i_in;
	reg [2+3-1:0] read_rq_filter [3:0];	
	reg [1+4:0] read_rq_reg [3:0]; // one more bit to say if vector
	reg [1:0] read_rq_i_out;

	wire [4:0] rd_read; assign rd_read   = read_rq_reg[read_rq_i_out];
	wire rd_read_v;     assign rd_read_v = read_rq_reg[read_rq_i_out][5];
	wire [2+3-1:0] rd_filter; assign rd_filter = read_rq_filter[read_rq_i_out];
	
	reg reg_pend [31:0];
		
	reg [`VLEN-1:0] reg_file_v [`NumVregisters-1:0]; reg reg_pend_v [`NumVregisters-1:0]; 
	
	wire [2:0] vrs1; assign vrs1 = instr[31:29];
	wire [2:0] vrd1; assign vrd1 = instr[28:26];
	wire [2:0] vrs2; assign vrs2 = instr[25:23];
	wire [2:0] vrd2; assign vrd2 = instr[22:20];	
	
	
	wire fetch_wait; 
	assign fetch_wait = ((!accepting) || ((read_rq_i_in+1)%4==read_rq_i_out));
	
	wire c1_not_accepting; // very specific to merge, can be removed for others (but also below)
	
	// Stall logic, according to the instruction type, as there are different data dependancy checks
	always @(*) begin

		case (iformat)
			`Rtype: halt =!readyI|| reg_pend[rs1] || reg_pend[rs2] ||reg_pend[rd] || (m_inst&&!m_acc) 
					    || (simd_inst && (reg_pend_v[vrd1] ||reg_pend_v[vrs1] || fetch_wait )); 
			`Itype: 
				halt =!readyI|| reg_pend[rs1] ||reg_pend[rd]|| (load_enable && (fetch_wait))
					 || ( simd_inst && (reg_pend_v[vrs1] || reg_pend_v[vrs2] //||reg_pend_v[vrd1] || reg_pend_v[vrd2]
					 || c1_not_accepting) );			 
			`Stype: 
				halt =!readyI|| reg_pend[rs1] || reg_pend[rs2] 
				 || (!accepting);
			`Btype: halt =!readyI|| reg_pend[rs1] || reg_pend[rs2];
			`Utype: halt=!readyI||reg_pend[rd];
			`Jtype: halt=!readyI||reg_pend[rd];
			default: halt=!readyI;
		endcase

	end
	
	// Registers holding the input data for all custom SIMD instructions
	wire [`VLEN-1:0] c_inA;  assign c_inA = reg_file_v[vrs1];
	wire [`VLEN-1:0] c_inB;  assign c_inB = reg_file_v[vrs2];
	wire [31:0] c_in;        assign c_in  = reg_file  [ rs1];
	
	wire [2:0] c_rd1;  assign c_rd1=vrd1;
	wire [2:0] c_rd2;  assign c_rd2=vrd2; 
	wire [4:0] c_rd;   assign c_rd =rd; 
	
	
	// **** Custom instructions placeholder ****
	wire [`VLEN-1:0] c1_outA; wire [`VLEN-1:0] c1_outB; wire [2:0] c1_out_rd1; wire [2:0] c1_out_rd2; 
	wire c1_out_v; wire c1_out;  wire [4:0] c1_out_rd;    
    wire c1_out_sv; 
    
    Merger2x8x32bit // This can be commented out if not used
             c1_merg (clk, reset, c_rd, c_rd1, c_rd2, c1_en&&!(halt), c_inA, c_inB, 
    		c1_out_v, c1_outA, c1_outB, c1_out_rd, c1_out_rd1, c1_out_rd2,
    		c1_out_sv, c1_out, c1_not_accepting);
    
    wire [`VLEN-1:0] c2_outA; wire [`VLEN-1:0] c2_outB; wire [2:0] c2_out_rd1; wire [2:0] c2_out_rd2; 
    wire c2_out_v; 		


    Sorter1x8x32bit // Can be removed or replaced with PrefixSum1x8x32bit etc.
    //PrefixSum1x8x32bit
   	        c2_s (clk, reset,       c_rd1,        c2_en&&!(halt), c_inA,      
    		c2_out_v, c2_outA,                     c2_out_rd1                    );
	
	
	/////// Instantiation of the dummy template ///////
	wire [`VLEN-1:0] c3_outA; wire [`VLEN-1:0] c3_outB; wire [2:0] c3_out_rd1; wire [2:0] c3_out_rd2; 
	wire c3_out_v; wire [31:0] c3_out;  wire [4:0] c3_out_rd; 
	
	C3_custom_SIMD_instruction
	              c3 (clk, reset, c3_en&&!(halt), c_rd, c_rd1, c_rd2, c_in, c_inA, c_inB, 
    		c3_out_v, c3_out_rd, c3_out_rd1, c3_out_rd2, c3_out, c3_outA, c3_outB);
    		         
	
	// **** Custom instructions placeholder end ****
	
	assign cycles=cycle_counter;
	always @(posedge clk) begin
		if (reset) begin

			for (i=0; i<32; i=i+1) begin
				reg_file[i]<=0;    reg_pend[i]<=0;			
			end	
			for (i=0; i<`NumVregisters; i=i+1) begin
				reg_file_v[i]<=0;  reg_pend_v[i]<=0;		
			end		
			
			reg_file[2] <= StackPointer;
			PC<=StartAddress;
			
			enB<=0;	weB<=0;	

			cycle_counter<=0;
			instr_counter<=0;
			
			read_rq_i_in<=0; read_rq_i_out<=0;
			for (i=0; i<4; i=i+1) begin
				read_rq_filter[i]<=0;
				read_rq_reg[i]<=0;
			end
			
		end else begin	
			cycle_counter<=cycle_counter+48'b1;		
			enB<=0;	weB<=0;	
			
			// On a valid result from custom instruction C1, update the registers, and mark them non-pending		
			if(c1_out_v) begin
				reg_file_v[c1_out_rd1]<=c1_outA;
				reg_file_v[c1_out_rd2]<=c1_outB;				 
				reg_pend_v[c1_out_rd1]<=0; reg_pend_v[c1_out_rd2]<=0;	
				
				if(`DEB) $display("C1_PEND finished %d",cycle_counter+1);		
			end			
			if (c1_out_sv) begin 
				// specific to merge, but a similar approach can be used if results are ready on different times
				reg_file[c1_out_rd]<=c1_out; reg_pend[c1_out_rd]<=0;
			end
			
			// On a valid result from custom instruction C2, update the registers, and mark them non-pending	
			if(c2_out_v) begin				
				reg_file_v[c2_out_rd1]<=c2_outA;
				reg_pend_v[c2_out_rd1]<=0;
				if(`DEB) $display("C2_PEND finished %d",cycle_counter+1);
			end
			
			// On a valid result from custom instruction C3, update the registers, and mark them non-pending		
			if(c3_out_v) begin
				reg_file[c3_out_rd]<=c3_out;		reg_pend[c3_out_rd]<=0;
				reg_file_v[c3_out_rd1]<=c3_outA;	reg_pend_v[c3_out_rd1]<=0;
				reg_file_v[c3_out_rd2]<=c3_outB;	reg_pend_v[c3_out_rd2]<=0;					
				if(`DEB) $display("C3_PEND finished %d",cycle_counter+1);		
			end	

			// On a valid result from an "M" instruction, store it and mark it non-pending
			if (m_ready) begin
				reg_file[m_rd]<=m_res;
				reg_pend[m_rd]<=0;
				if (`DEB)$display("MULTI %d -> x%d, cycle: %d, instr %d", m_res, m_rd, cycle_counter, instr_counter);
				if(`DEB)$display("MULT_PEND finished %d",cycle_counter+1);
			end
			
			// On arriving reads from caches
			if (readyB) begin
				read_rq_i_out<=read_rq_i_out+1;

				if(`DEB)$display("LOAD_PEND finished %d",cycle_counter+1);
				
				// If it is for a 32-bit register, manipulate it according to the requested format
				if (!rd_read_v) begin
				
					reg_pend[rd_read]<=0;
					
					if (`DEB)$display("x%d released cyc%d %h",rd_read,cycle_counter, dinB);
					case(rd_filter[2:0])
						3'h0: reg_file[rd_read]<= // lb   {{24{dinB[ 7]}},dinB[ 7:0]};
					{{24{dinB[(rd_filter[4:3]+1)*8-1]}},  dinB[(rd_filter[4:3]+1)*8-1-:8]};   
						3'h1: reg_file[rd_read]<= // lh   {{16{dinB[15]}},dinB[15:0]}; 
					{{16{dinB[(rd_filter[4]  +1)*16-1]}}, dinB[(rd_filter[4]  +1)*16-1-:16]}; 
						3'h2: reg_file[rd_read]<=dinB; // lw
						3'h4: reg_file[rd_read]<= // lbu          {24'b0, dinB[ 7:0]};
								                  {24'b0, dinB[(rd_filter[4:3]+1)*8-1-:8]};
						3'h5: reg_file[rd_read]<= // lhu          {16'b0, dinB[15:0]};
								                  {16'b0, dinB[(rd_filter[4]  +1)*16-1-:16]}; 
						default: ;                              
					endcase
					
					if (`DEB)if (
						((rd_filter[2:0]==1)&&(rd_filter[3]==1)) ||
						((rd_filter[2:0]==5)&&(rd_filter[3]==1)) ||
						((rd_filter[2:0]==2)&&(rd_filter[4:3]!=0)) 
						) $display("ERROR: alignment");
					if (`DEB)$display("reading",rd_read,read_rq_reg[read_rq_i_out],read_rq_i_out," ",dinB," ",rd_filter );
				// If it was from a vector load, then allignement is assumed
				end else begin
					reg_pend_v[rd_read]<=0;
					reg_file_v[rd_read]<=dinB;
					
					if (`DEB)$display("SIMD read %h to v%d cyc%d",dinB, rd_read,cycle_counter);
				end	
				
			end 
			
			// If there is no stall proceed to update PC and do the rest of the tasks happening in a cycle
			if (!halt) begin
				PC<=PCnext; 	
				instr_counter<=instr_counter+1;
				
				if (`DEB)$display("%h %h %h %h %h %h %h %h |%h", reg_file[10], reg_file[11], reg_file[12], reg_file[13], reg_file[9], reg_file[13], reg_file[14], reg_file[15], doutB);
				if (`DEB)$display("PC: %h ( %d ) %h Instr: %h x %d %d %d im%h fun%d dad%h ha%d cyc %d", PC,PC,PCnext, instr, rs1, rs2,rd,immediate, alu_func,addrB, halt,cycle_counter);
				
				// According to the istruction type, bahave differently
				case (iformat)
					`Rtype: begin 
								reg_file[rd]<=alu_dst; 
								if (`DEB)if(alui_enable)$display("%d(%d_%d)->x%d, cycle: %d, instr %d ",alu_dst,alu_rs1,alu_rs2, rd, cycle_counter, instr_counter);
								reg_pend[rd]<=0;
								
								if (simd_inst && (func3==2)) begin 
									if (`DEB)$display("SIMDwrite %h from v%d daddr %h cyc%d PC%h", reg_file_v[vrs1],vrs1, daddr,cycle_counter,PC);
									doutB <= reg_file_v[vrs1];
									weB<={(`VLEN/8){1'b1}};
									addrB <= {daddr[`DADDR_bits-1:`VLEN_Log2-3],{(`VLEN_Log2-3){1'b0}} };
								end
								
							end				
								
					`Itype: begin 
								if (alui_enable) begin	
									reg_file[rd] <= alu_dst; 
									if (`DEB)$display("%h->x%d from %h %h PC %h",alu_dst, rd,alu_rs1, alu_rs2,PC);
								end 
								if (absolute_pc) begin
									reg_file[rd] <= pc4;
								end	
								if (counters) begin 
									if (`DEB)$display("Counter %h %h -> x%d imm %b",instr_counter, cycle_counter , rd, {immediate[7],immediate[1:0]});
									
									case({immediate[7],immediate[1:0]}) 
										3'b000: reg_file[rd] <=cycle_counter [31: 0];    // rdcycle
										3'b001: reg_file[rd] <=cycle_counter [31: 0]<<3; // rdtime  (8 ns per cycle for 125 MHz)
										3'b010: reg_file[rd] <=instr_counter [31: 0];    // rdinstret
										3'b100: reg_file[rd] <=cycle_counter [47:32];    // rdcycleh
										3'b101: reg_file[rd] <=cycle_counter [47:32+3];  // rdtimeh (8 ns per cycle for 125 MHz)
										3'b110: reg_file[rd] <=instr_counter [47:32];    //rdinstreth
									endcase									
								end							
								reg_pend[rd]<=0;
								
								if (simd_inst) begin 
									reg_pend[rd]<=1; 
									reg_pend_v[vrd1]<=1; 
									reg_pend_v[vrd2]<=1;																
								end	
								
							end
					`Stype: begin 
							
							// For stores, update the write bits for the DL1 (weB) and data (doutB), according to the command			
							doutB <= reg_file[rs2]; 				
							case(func3)
								3'h0: begin // sb
									weB<=(1'b1)<<daddr[1:0];
									doutB <= reg_file[rs2]<<(8*daddr[1:0]);
									
									 end 
								3'h1: begin // sh
									weB<=(2'b11)<<(2*daddr[1]); 
									doutB <= reg_file[rs2]<<(16*daddr[1]);
									if (`DEB)if (daddr[0]!=0)$display("ERROR");

									end 
								3'h2: begin 
									weB<=4'b1111; // sw
									if (`DEB)if (daddr[1:0]!=0)$display("ERROR");
									end
								default: weB<=0;                              
							endcase 			
							
							addrB <= {daddr[`DADDR_bits-1:2],2'b0};
							
							// Just a simple way to read stdout (at address 0x07000000) in simulation
							if (`STDO) if (daddr[28-1-:4]==7)
								 $write("%s",reg_file[rs2][7:0]);

						end
					`Btype: ;
					`Utype: begin 
								reg_file[rd]<=(auipc_enable)?auipc:immediate; 
								reg_pend[rd]<=0;
						end
					`Jtype: begin 
								reg_file[rd]<=pc4; 
								reg_pend[rd]<=0;
						end
					default: ;
				endcase	
				
				// On loads, make the request to the caches, and keep the rd (or vrd for SIMD)
				if (load_enable) begin
					enB<=1;										
					read_rq_i_in<=read_rq_i_in+1;
					if (simd_inst) begin
						reg_pend_v[vrd1]<=1;						
						if (`DEB)$display("v%d pending",vrd1);
						read_rq_reg[read_rq_i_in]<=6'b100000 |vrd1;
					end else begin
						reg_pend[rd]<=1;						
						if (`DEB)$display("x%d pending",rd);
						read_rq_reg[read_rq_i_in]<=rd;
					end

					read_rq_filter[read_rq_i_in]<={daddr[1:0],func3};
					addrB <= {daddr[`DADDR_bits-1:2],2'b0};
				end
							
				if (m_inst) begin
					reg_pend[rd]<=1;
				end 
				
				// (Only useful for the timeline plot)
				if (`DEB) begin 
					if(load_enable)
						$display ("plot %d %d LOAD_PEND",PC, cycle_counter);
					else if (m_inst)
						$display ("plot %d %d MULT_PEND",PC, cycle_counter);
					else if ((iformat==`Stype)||simd_inst && (func3==2) )
						$display ("plot %d %d STORE_PEND",PC, cycle_counter);
					else if (simd_inst && c1_en)
						$display ("plot %d %d C1_PEND",PC, cycle_counter);
					else if (simd_inst && c2_en)
						$display ("plot %d %d C2_PEND",PC, cycle_counter);
					else if (simd_inst && c3_en)
						$display ("plot %d %d C3_PEND",PC, cycle_counter);
					else begin
						$display("plot %d %d NO_PEND",PC, cycle_counter);			
						$display("NO_PEND finished %d",cycle_counter+1);
					end	 
				end
				
			end	else begin
				
			end		
			
			// Registers x0 and v0 represent 0. They are removed by the implementation tools automatically.
			reg_file  [0]<=0;		reg_pend  [0]<=0;	
			reg_file_v[0]<=0;		reg_pend_v[0]<=0;
		end	
		
	end
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, PC, PCnext, instr, enB, weB, accepting, halt,read_rq_i_out, read_rq_i_in,iformat, cycle_counter, rs1,rs2,rd,next_direction,next_step, vrs1, vrs2, vrd1, vrd2, func3, immediate,instr_counter);
	end
endmodule // Core
	



