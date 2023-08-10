
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


struct Compressed_sparse{
    std::vector<uint32_t> vals;
    std::vector<int> count;
    std::vector<int> index;
};


int generate_random_value(){
    return (uint32_t)rand() % 100;
}

uint32_t *generate_sparse_matrix(int N, int density){

    // density cannot be approximate. It must be exact. Hence, get number of elements then place them randomly


    int element_count=16*density/100;
    int placed_elements=0;

    uint32_t * _A = new uint32_t [N*N];

    int A_bitmap[N][N];

    for(int i=0; i<N;i++){
        for(int j=0;j<N;j++){
            _A[i*N+j] = 0;
            A_bitmap[i][j]=0;
        }
    }

    while(placed_elements!=element_count){
        int row= rand()%4;
        int col= rand()%4;
        if(A_bitmap[row][col]==0){
            _A[row*N+col]=rand()%RAND_MAX;
            A_bitmap[row][col]=1;
            placed_elements++;
        }

    }

    return _A;
}


uint32_t *generate_empty_matrix(int N){
    uint32_t * _A = new uint32_t [N*N];
    for(int i=0; i<N*N;i++){
        _A[i] = 0;
    }
    return _A;
}



void print_matrix(int N, uint32_t *A){
    for(int i=0;i<N;i++){
        for(int j=0;j<N;j++){
            printf("%0d ", A[i*N+j]);
        }
        printf("\n");
    }
        printf("\n");
        printf("\n");
}

Compressed_sparse get_csc(int N, uint32_t *A){
    int counter=0;

    Compressed_sparse csc;

    std::vector<uint32_t> vals;
    std::vector<int> count(1,0.0);
    std::vector<int> rowIndex;

    for(int j=0;j<N;j++){
        for(int i=0;i<N;i++){
            if(A[i*N+j] != 0){
                vals.push_back(A[i*N +j]);
                rowIndex.push_back(i);
                counter+=1;
            }
        }
        count.push_back(counter);
    }

    csc.count=count;
    csc.vals=vals;
    csc.index=rowIndex;


    return csc;
}


void SPMM(int N, Compressed_sparse A_csc, uint32_t *B, uint32_t *C){

    int i=0;
    int B_row = 0;

    while(i<N){
        //printf("test");
        for(int A_ptr = A_csc.count[i]; A_ptr < A_csc.count[i+1]; A_ptr++){
            int row = A_csc.index[A_ptr];
            for(int k=0; k<N; k++){
                C[row *N+k]+=A_csc.vals[A_ptr] * B[B_row * N +k];
            }
        }
        B_row++;
        i++;
    }
    //return C;
}


void test(){
    return;
}


#ifdef SIMODENSE
void main() {
#else
int main(){
#endif

    printf("\n\n\n\n");
    #ifdef SIMODENSE
    printf("SIMODENSE DEFINED");
    #endif

    printf("\n=====\nRUNNING SGEMM BENCHMARKS\n=====\n");


    int N = 4;
    //uint32_t *A = generate_sparse_matrix(4, 20);
    //print_matrix(N, A);
    //A = generate_sparse_matrix(4, 20);
    //print_matrix(N, A);
    //A = generate_sparse_matrix(4, 20);
    //print_matrix(N, A);
    //printf("done");


    // Step 1: Generate all matricies in advance:

    for(int density=5;density<=100;density+=5){
        int sample_count=100;
        uint32_t *A[sample_count];
        Compressed_sparse A_csc[sample_count];
        uint32_t *B[sample_count];
        uint32_t *C[sample_count];


        for(int i=0;i<sample_count;i++){
            A[i]=generate_sparse_matrix(N, density);
            B[i]=generate_sparse_matrix(N,100); 
            C[i] = generate_empty_matrix(N);
            A_csc[i] = get_csc(N, A[i]);
            //print_matrix(N,A[i]);
            //print_matrix(N, B[i]);
            //print_matrix(N,C[i]);
        }


        // Step 2: measure SW impl. of SPMM


        for (int i=0;i<sample_count;i++){
            // Get number of cycles and instructions before	  		
            #ifdef SIMODENSE
            uint64_t time1=time(); 
            uint64_t icount1=insn();
            #endif
            // Do stuff

            SPMM(N, A_csc[i], B[i], C[i]);

            //print_matrix(N,A[i]);
            //print_matrix(N, B[i]);
            //print_matrix(N,C[i]);

            // and after calling the prefix_sum_simd function
            #ifdef SIMODENSE
            uint64_t end=time();
            uint64_t elapsed=end-time1;
            //uint64_t icount2=insn()-icount1;  
            #endif
            
            // Print statistics  		  		
        
            #ifdef SIMODENSE
            printf("{Density, Cycles} {%d, %d}\n", density, elapsed);
            #endif
        }


        for(int i=0;i<sample_count;i++){
            free(A[i]);
            free(B[i]);
            free(C[i]);
        }


    }


    
    return;
}
