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

`define DEB 0  // DEB = 1 enables the waveform generation and (meaningless) debugging comments
`define STDO 1 // Enables stdout in simulation

`include "cpu.v"
`include "caches.v"
`include "custom.v"

module System(clk, reset, StartAddress, StackPointer,      
        addrD, doutDstrobe, doutD, dinDstrobe, dinD, enD, weD, readyD, accR, accW,
        debug, flush, flushed);
	input clk, reset;	
	
	input [`IADDR_bits-1:0] StartAddress;
    input [`DADDR_bits-1:0] StackPointer;
	        
    output [`DADDR_bits-1:0] addrD;
    output [`DL2subblocks_Log2-1:0] doutDstrobe;
    output [`DL2block/`DL2subblocks-1:0] doutD;
    input [`DL2subblocks_Log2-1:0] dinDstrobe;
    input [`DL2block/`DL2subblocks-1:0] dinD;    
    output enD;
    output weD;
    input readyD;
    input accR;
    input accW;
    
    output [31:0] debug;
    input flush;
    output flushed;          
    
    wire [`IADDR_bits-1:0] addrA;
    wire [31:0] doutA;    
    
    wire [`DADDR_bits-1:0] addrB;
    wire [`VLEN-1:0] dinB;
    wire [`VLEN-1:0] doutB;   
     
    wire enB;
    wire [`VLEN/8-1:0] weB;
    wire readyB;
    
    wire acceptingB;    
    
	wire readyA;
	wire enI; wire [`IADDR_bits-1:0] addrI; wire [`VLEN-1:0] doutI; wire readyI;
	
	IL1Cache il1 (clk, reset, addrA, doutA, readyA,
		enI, addrI, doutI, readyI);
    
    wire [`DADDR_bits-1:0] addrC;
    wire [`VLEN-1:0] dinC;
    wire [`VLEN-1:0] doutC;      
    wire enC;
    wire weC;
    wire dreadyC;    
    wire acceptingC;
        
    wire flush_l2;
    wire [31:0] cycles;
    
    DL1cache dc1(clk, reset, cycles,
		addrB, enB, weB, dinB, doutB, readyB, acceptingB, flush,
		addrC, enC, weC, dinC, doutC, dreadyC, acceptingC, flush_l2);     
    
    DL2cacheU dc2(clk, reset, 
    	enI, addrI, doutI, readyI,
		addrC, enC, weC, dinC, doutC, dreadyC, acceptingC, flush_l2,
		addrD, enD, weD, dinDstrobe, dinD, doutDstrobe, doutD, readyD, accR, accW, flushed); 		
    
    wire halt;    
    Core c0(clk, reset, cycles,    	
		addrA, doutA, readyA, StartAddress, StackPointer,
		addrB, doutB, dinB, enB, weB, readyB, acceptingB, halt
	);    
   
	assign debug={halt,addrA}; // (Also useful for detecting end of execution in simulation)
	   
endmodule // System8



