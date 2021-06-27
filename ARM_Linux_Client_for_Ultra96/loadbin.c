
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "stdint.h"

#define Base 0x40000000
#define MAP_SIZE 0x1000000
#define MAP_MASK (MAP_SIZE - 1)

#define MIN(a,b) (((a)<(b))?(a):(b))

int main(int argc, char** argv) {
	FILE *ptr = fopen("firmware.bin","rb"); 
	
	int memfd = open("/dev/mem", O_RDWR | O_SYNC);
	
	void *mapped_base, *mapped_dev_base;
	mapped_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, memfd, Base & ~MAP_MASK);
	mapped_dev_base = mapped_base + (Base & MAP_MASK);
	
	*((volatile uint64_t*)(mapped_base))=0xffffffff;
	
	fseek(ptr, 0L, SEEK_END);
	int file_size = ftell(ptr);
	printf("File size is %d\n", file_size);
	rewind(ptr);
	
	
	uint64_t data=0;
	for (int i=0; i<file_size; i+=4){
		uint32_t datar=0;
		int size = MIN(4,file_size-i);
		fread(&datar, size, 1, ptr);
		
		if (i%8==0){
			data=data|(((uint64_t)datar)<<32);
			*((volatile uint64_t*)(mapped_base+i+0x10070))=data;
		} else {
			data=datar;
			*((volatile uint64_t*)(mapped_base+i+4+0x10070))=data;
		}
	} 
	
	
	
	if (munmap(mapped_base, MAP_SIZE) == -1) {
		printf("Can't unmap memory from user space.\n");
		exit(0);
	}
		
    return (EXIT_SUCCESS);
}

