
#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <limits.h>
#include <sys/signal.h>
#include <cmath>
#include <vector>
#include <stdlib.h>

#ifdef SIMODENSE
    #include "syscalls.c"
#endif

void add_list(uint32_t* inA, uint32_t* inB, uint32_t* dest, size_t len)
{ 
	int incr = 4; // 4 for 128-bit registers, 8 for 256-bit	
	
	for (int i=0; i<len; i+=incr*4){  	  	

        #ifdef SIMODENSE
		// Load 8 elements of each lists into vectors v1 and v2
	  	asm volatile ("c0_lv x0, %0, %1, %2":: "r"(inA), "r"(i), "I"(1<<(6)) );
		asm volatile ("c0_lv x0, %0, %1, %2":: "r"(inB), "r"(i), "I"(2<<(6)) );
		
	  	// Store restult of the result vector (v3)
	  	asm volatile ("c0_sv x0, %0, %1, %2":: "r"(i   ), "r"(dest), "I"(3<<(6+3)) );
        #endif
  	}
}


#ifdef SIMODENSE
void main() {
#else
int main(){
#endif

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




    printf("\n\n\n\n");
    #ifdef SIMODENSE
    printf("SIMODENSE DEFINED");
    #endif

    printf("\n=====\nRUNNING SGEMM BENCHMARKS\n=====\n");


    for(int i=0;i<300;i++){

        // Note: this code does not account for the fact that
        // the first mem access will be a miss, while following will be hits
        // Oranges to oranges- what ~should~ I force? all hits or all misses?

        #ifdef SIMODENSE
        uint64_t start=time(); 
        #endif
        // Do stuff

        for(int vec=0;vec<4;vec++){
            add_list(srcA, srcB,  destA, len);  // matricies are assumed to be 4x4 
                                                // when loaded into the STPU/TPU
        }

        // and after calling the prefix_sum_simd function
        #ifdef SIMODENSE
        uint64_t end=time();
        uint64_t elapsed=end-start;
        //uint64_t icount2=insn()-icount1;  
        #endif
            
        // Print statistics  		  		
        
        #ifdef SIMODENSE
        printf("{Density, Cycles} {%d, %d} \n", 0, elapsed);
        #endif
  

    }

    
    return;
}
