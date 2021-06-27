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


void sort_chunks(uint32_t* dest, uint32_t* src, size_t len);
int comp (const void * elem1, const void * elem2);
void mergeSort(uint32_t* src,int l,int r);
int mergeSort_worker(uint32_t* src,int l,int r);
void memcpy_simd(uint32_t* dest, uint32_t* src, size_t len);

uint32_t* tmpv=((volatile uint32_t*)(0x04600000));

void main(int argc, char** argv) {
	uint32_t outp=0x0400fff0;
	
	int a=rand();
	//printf("Hello!\n");

    
    uint32_t* srcA = 0x05000000; 
    uint32_t* srcB = 0x06000000;

    // Uncomment for the real FPGA instead, where 1GB is available
    // uint32_t* srcA = 0x50000000;
    // uint32_t* srcB = 0x60000000;

	// Temporary memory location to keep a series of -1s
	for (int i=0;i<32;i++){ //8 for 256-bit vector
		tmpv[i]=-1;
	}

	for (size_t len=16*4; len<=2048/*33554432*/*4; len*=2){

		// Prepare two identical lists of random numbers
		for (int j=0; j<len/4; j++) {
			int x=rand();//%len;
		    *((volatile uint32_t*)(srcA+j))=x;
			*((volatile uint32_t*)(srcB+j))=x;
		}   

		// Read cycles and instruction count	  		
		uint64_t time1=time(); 
		uint64_t icount1=insn();
		
		// Two phase merge sort
		sort_chunks(srcA, srcA, len);
		mergeSort(srcA,0,len/4);

		// Read cycles and instruction count	
		uint64_t time2=time()-time1;
		uint64_t icount2=insn()-icount1;  
		  		  	
	  	// Print result	
	  	printf("SIMDsort N %d cyc %llu icount %llu CPI %llu.%02llu ",
	  	len/4,time2, icount2,(time2)/(icount2), 	(((time2)%(icount2))*100)/(icount2));
	  	
	  	uint64_t int_part = len*150/time2;
	  	uint64_t dec_part = ((len*150)%time2)*100/time2;
	  	printf("MB/s@150MHz %llu.%02llu ",int_part,dec_part);
		
		// Do the same for qsort()
		volatile uint64_t time3_=time(); 
		qsort (srcB, (len/4), sizeof(int), comp);
		uint64_t time3=time()-time3_;
		
		// Print result
		printf("qsort_cyc %llu sp %llu.%02llu",time3, time3/time2, ((time3%time2)*100)/time2);
		
		int error=0;
		for (int i=0; i<len/4; i++)
			if (srcA[i]!=srcB[i])
	  			error=1;// printf("\n%d) %d != %d",i,srcA[i],srcB[i]);
	  	printf(" End%d!\n",error);	 
    }
    
    while (1);
    return;
}


// (imm. format vrs1, vrd1, vrs2, vrd2)
#define v1_and_v2  ((((((( 1 <<3)| 1 ))<<3)| 2 )<<3)| 2)
#define v1  ((((((( 1 <<3)| 1 ))<<3)| 0 )<<3)| 0)
#define v2  ((((((( 2 <<3)| 2 ))<<3)| 0 )<<3)| 0)

// Sort-in-chunks function
void sort_chunks(uint32_t* dest, uint32_t* src, size_t len)
{ 
  int incr = sizeof(int)*2*4; // sizeof(int)*4*2 for 2 256-bit registers
  
  for (int i=0; i<len; i+=incr*2){
	// Load vectors to v1 and v2
  	asm volatile ("c0_lv x0, %0, %1, %2":: "r"(i   ), "r"(src), "I"(1<<(6)) );
  	asm volatile ("c0_lv x0, %0, %1, %2":: "r"(i+incr), "r"(src), "I"(2<<(6)) );
  	
  	// Sort them individually 
  	asm volatile ("c2 x0, x0, %0":: "I"(v1));
  	asm volatile ("c2 x0, x0, %0":: "I"(v2));
  	
  	// And then merge together
  	asm volatile ("c1 x0, x0, %0":: "I"(v1_and_v2));
  	
  	// Store vectors v1 and v2
  	asm volatile ("c0_sv x0, %0, %1, %2":: "r"(i   ), "r"(dest), "I"(1<<(6+3)) );
  	asm volatile ("c0_sv x0, %0, %1, %2":: "r"(i+incr), "r"(dest), "I"(2<<(6+3)) );
  }
}

// Custom memcpy() that uses the registers
void memcpy_simd(uint32_t* dest, uint32_t* src, size_t len)
{ // when using malloc be careful to use alligned malloc
  int incr = 256/8; // 256-bit registers
  for (int i=0; i<len; i+=incr){
  	
  	asm volatile ("c0_lv x0, %0, %1, %2":: "r"(i), "r"(src), "I"(1<<(6)) );
  	asm volatile ("c0_sv x0, %0, %1, %2":: "r"(i), "r"(dest), "I"(1<<(6+3)) );
  }
}

// RS1, RD1, RS2, RD2 -> 1, 3, 2, 0
#define imm2  ((((((( 1 <<3)| 3 ))<<3)| 2 )<<3)| 0)
#define imm3  ((((((( 1 <<3)| 0 ))<<3)| 2 )<<3)| 3)
void merge_simd(uint32_t* inA, uint32_t* inB, uint32_t* dest, size_t lenA, size_t lenB)
{ 
	int incr = 8; // 4 for 128-bit registers, 8 for 256-bit	
	
  	uint32_t* inA_end = inA+(lenA/4);
  	uint32_t* inB_end = inB+(lenB/4);
  	uint32_t* dest_end = dest+(lenB/2);
  	int next_source;
  	  	
	// Load first 4 elements of each lists into vectors v1 and v2
  	asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inA), "I"(1<<(6)) ); inA+=incr;
  	asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inB), "I"(2<<(6)) ); inB+=incr;

	// Do the first merge
   	asm volatile ("c1 %0, x0, %1":"=r" (next_source): "I"(imm2));

   	// And update both v1 and v2 (next code will take care of the next_source)
	if (!next_source) {
  		if (inB!=inB_end){
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inB), "I"(2<<(6)) );  inB+=incr;
  		} 
  	} else {
  		if (inA!=inA_end){
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inA), "I"(1<<(6)) );  inA+=incr;
  		} 
  	}
	
	while (inA!=inA_end && inB!=inB_end){	
		
		// Based on the last call of c1, fetch either from A or B
  		if (next_source) {
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inB), "I"(2<<(6)) );  inB+=incr;
  		} else {
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inA), "I"(1<<(6)) );  inA+=incr;		
  		}
  		
  		// Store bottom of the current vectors (v3)
  		asm volatile ("c0_sv x0, x0, %0, %1":: "r"(dest), "I"(3<<(6+3)) ); dest+=incr;
  		
  		// Merge using current vectors
  		asm volatile ("c1 %0, x0, %1":"=r" (next_source): "I"(imm2));  		
  	}
  	
  	// Store bottom of the current vectors (v3)
  	asm volatile ("c0_sv x0, x0, %0, %1":: "r"(dest), "I"(3<<(6+3)) ); dest+=incr;
  	

	// Handle ending in a similar manner, but add "-1"s whenever one input finishes
	while (dest!=dest_end){ 
		
  		if (next_source) {
  			if (inB!=inB_end){
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inB), "I"(2<<(6)) );  inB+=incr;
  			} else
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(tmpv), "I"(2<<(6)) ); 
  		}
  		
  		if (!next_source){
  			if (inA!=inA_end){
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(inA), "I"(1<<(6)) );  inA+=incr;
  			} else
  			asm volatile ("c0_lv x0, x0, %0, %1":: "r"(tmpv), "I"(1<<(6)) ); 		
  		}
  		
  		asm volatile ("c1 %0, x0, %1":"=r" (next_source): "I"(imm2));
  		
  		asm volatile ("c0_sv x0, x0, %0, %1":: "r"(dest), "I"(3<<(6+3)) ); dest+=incr;
  	}
	
	// Reset the state of merge for the next call, by setting rd=0 (x0)
	asm volatile ("c1 x0, x0, %0":: "I"(0));		
}

// Merge sort implementation
void mergeSort(uint32_t* src,int l,int r){

	// Call the recursive function
	int dest_phase=mergeSort_worker(src,l,r);
	uint32_t* tmp= 0x70000000;
	
	// But transfer the temporary data to the result, in case the result ended up there
	if (dest_phase==1){
		memcpy_simd(src,tmp,r*4);
	}
}

// Recursive merge function
int mergeSort_worker(uint32_t* src,int l,int r){

    if(l+16==r){ 
    	// 16-element chunks have been already sorted  	
        return 0;
    }

    int m = (l+r)/2;
    
    // Call the recursive function twice
    mergeSort_worker(src,l,m);
    int dest_phase = mergeSort_worker(src,m,r);
    
    int len = (r-l)/2;

    uint32_t* tmp;
    if (dest_phase==0){
    	tmp = 0x70000000;    	
    } else {
    	tmp = src;
    	src = 0x70000000;    
    }
    
    // High-throughput merge using the merge_simd() function     
    merge_simd(src+l, src+l+len ,tmp+l, len*4, len*4);        
    
    return !dest_phase;
}


// Comparator for ascending elements
int comp (const void * elem1, const void * elem2) 
{
    int f = *((int*)elem1);
    int s = *((int*)elem2);
    if (f > s) return  1;
    if (f < s) return -1;
    return 0;
}
