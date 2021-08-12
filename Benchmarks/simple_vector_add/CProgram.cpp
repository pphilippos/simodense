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

