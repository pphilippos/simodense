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

void add_list(uint32_t* inA, uint32_t* inB, uint32_t* dest, size_t len);

void main(int argc, char** argv) {
	
	int a=rand();
	//printf("Hello!\n");
    
    uint32_t* srcA = 0x05000000; 
    uint32_t* srcB = 0x05800000;
    uint32_t* destA = 0x06000000;
	uint32_t* destB = 0x06800000;
	    
	size_t len=64*4; 

	// Prepare two lists of random numbers
	for (int j=0; j<len/4; j++) {
	    *((volatile uint32_t*)(srcA+j))=rand()%len;
		*((volatile uint32_t*)(srcB+j))=rand()%len;
		destA[j]=0;
	}   

	// Read cycles and instruction count	  		
	uint64_t time1=time(); 
	uint64_t icount1=insn();
	
	// Add lists
	add_list(srcA, srcB,  destA, len);

	// Read cycles and instruction count	
	uint64_t time2=time()-time1;
	uint64_t icount2=insn()-icount1;  
	  		  	
  	// Print result	
  	printf("vectorADD N %d cyc %llu icount %llu CPI %llu.%02llu ",
  	len/4,time2, icount2,(time2)/(icount2), 	(((time2)%(icount2))*100)/(icount2));
  	
  	uint64_t int_part = len*150/time2;
  	uint64_t dec_part = ((len*150)%time2)*100/time2;
  	printf("MB/s@150MHz %llu.%02llu ",int_part,dec_part);
	
	// Do the same serially
	volatile uint64_t time3_=time(); 
	for (int i=0; i<len/4; i+=1){
		//destA[i]=0;
		destB[i]=srcA[i]+srcB[i];
	}
	uint64_t time3=time()-time3_;
	
	// Print result
	printf("serialADD %llu sp %llu.%02llu",time3, time3/time2, ((time3%time2)*100)/time2);
	
	int error=0;
	for (int i=0; i<len/4; i++){
		if (destA[i] != destB[i]){
  			error=1; 
  		}
  		printf("\n%d) (%d + %d)\tvector: %d\t serial:%d", i, srcA[i], srcB[i], destA[i], destB[i]);  		
  	}	
  	printf("\nEnd%d!\n",error);	 
    
    
    while (1);
    return;
}

// RS1, RD1, RS2, RD2 -> 1, 3, 2, 0
#define v1_plus_v2_to_v3  ((((((( 1 <<3)| 3 ))<<3)| 2 )<<3)| 0)

void add_list(uint32_t* inA, uint32_t* inB, uint32_t* dest, size_t len)
{ 
	int incr = 8; // 4 for 128-bit registers, 8 for 256-bit	
	
	for (int i=0; i<len; i+=incr*4){  	  	

		// Load 8 elements of each lists into vectors v1 and v2
	  	asm volatile ("c0_lv x0, %0, %1, %2":: "r"(inA), "r"(i), "I"(1<<(6)) );
		asm volatile ("c0_lv x0, %0, %1, %2":: "r"(inB), "r"(i), "I"(2<<(6)) );

		// Add them to v3
	   	asm volatile ("c3 x0, x0, %0":: "I"(v1_plus_v2_to_v3));
		
	  	// Store restult of the result vector (v3)
	  	asm volatile ("c0_sv x0, %0, %1, %2":: "r"(i   ), "r"(dest), "I"(3<<(6+3)) );
  	}
}

