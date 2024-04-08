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

#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <limits.h>
#include <sys/signal.h>
#include <stdlib.h>
#include "syscalls.c"

 
void prefix_sum_simd(uint32_t* dest, uint32_t* src, size_t len);
void prefix_sum(uint32_t* dest, uint32_t* src, size_t len);

void main(int argc, char** argv) {

	uint32_t outp=0x0400fff0;
    
    uint32_t* srcA = 0x05000000; 
    uint32_t* srcB = 0x05800000;
    uint32_t* dstA = 0x06000000; 
    uint32_t* dstB = 0x06800000;
    
    // Uncomment the following instead, for the real FPGA (1GB available)
    //uint32_t* srcA = 0x50000000;
    //uint32_t* srcB = 0x60000000;
    //uint32_t* dstA = 0x60000000; 
    //uint32_t* dstB = 0x68000000;
    
    for (size_t len=/*16*/32*4; len<=4096/*33554432*/*4; len*=2){

		for (int j=0; j<len/4; j++) {
			int x=rand()%len;
		    *((volatile uint32_t*)(srcA+j))=x;
			*((volatile uint32_t*)(srcB+j))=x;
		}   
			  		
		// Get number of cycles and instructions before	  		
		uint64_t time1=time(); 
		uint64_t icount1=insn();

		prefix_sum_simd(dstA, srcA, len);

		// and after calling the prefix_sum_simd function
		uint64_t time2_=time();
		uint64_t time2=time2_-time1;
		uint64_t icount2=insn()-icount1;  
		 
		// Print statistics  		  		
	  	printf("SIMDprefix N %d cyc %llu icount %llu CPI %llu.%02llu ",
	  	len/4,time2, icount2,(time2)/(icount2), 	(((time2)%(icount2))*100)/(icount2));
	  	
	  	uint64_t int_part = len*150/time2;
	  	uint64_t dec_part = ((len*150)%time2)*100/time2;
	  	printf("MB/s@150MHz %llu.%02llu ",int_part,dec_part);
		
		// Do the same for the serial version of prefix sum
		volatile uint64_t time3_=time(); 
		
		prefix_sum(dstB, srcB, len);
		
		uint64_t time3=time()-time3_;

		// And print the cycles of the serial 
		printf("serial_cyc %llu sp %llu.%02llu",time3, time3/time2, ((time3%time2)*100)/time2);
		
		for (int i=0; i<len/4; i++)
			if (dstA[i]!=dstB[i])
	  			printf("%d) %d != %d\n",i,dstA[i],dstB[i]);
	  	printf(" end!\n");	 
	  	
    }
    while (1);
    return;
}

// (imm. format vrs1, vrd1, vrs2, vrd2)
#define v1_and_v2  ((((((( 1 <<3)| 1 ))<<3)| 2 )<<3)| 2)
#define v0  ((((((( 0 <<3)| 0 ))<<3)| 0 )<<3)| 0)
#define v1  ((((((( 1 <<3)| 1 ))<<3)| 0 )<<3)| 0)
#define v2  ((((((( 2 <<3)| 2 ))<<3)| 0 )<<3)| 0)

void prefix_sum_simd(uint32_t* dest, uint32_t* src, size_t len)
{ 
  int incr = sizeof(int)*2*4; // sizeof(int)*2*4 for 2 256-bit registers
  
  for (int i=0; i<len; i+=incr*2){
	// Load vectors to v1 and v2
  	asm volatile ("c0_lv x0, %0, %1, %2":: "r"(i   ), "r"(src), "I"(1<<(6)) );
  	asm volatile ("c0_lv x0, %0, %1, %2":: "r"(i+incr), "r"(src), "I"(2<<(6)) );
  	
  	// Individually 
  	asm volatile ("c2 x0, x0, %0":: "I"(v1));
  	asm volatile ("c2 x0, x0, %0":: "I"(v2));
  	
  	// Store vectors v1 and v2
  	asm volatile ("c0_sv x0, %0, %1, %2":: "r"(i   ), "r"(dest), "I"(1<<(6+3)) );
  	asm volatile ("c0_sv x0, %0, %1, %2":: "r"(i+incr), "r"(dest), "I"(2<<(6+3)) );
  }
  asm volatile ("c2 x0, x0, %0":: "I"(v0)); //Reset
}

void prefix_sum (uint32_t* dest, uint32_t* src, size_t len){
	int sum=0;
	for (int i=0; i<len; i+=4){
		sum+=*(src++);
		*(dest++)=sum;
	}
}

