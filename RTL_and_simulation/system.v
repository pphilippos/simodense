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



