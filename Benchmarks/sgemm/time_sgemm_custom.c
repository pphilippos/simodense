#include "stdio.h"
#include <cmath>
#include <cblas.h>
#include "stdlib.h"
#include "sys/time.h"
#include "time.h"


#define MAX_RAND_INT 2147483647/2

int generate_random_value(){
    return rand()/MAX_RAND_INT;
}

int * generate_random_matrix(int N){
    float* A = (int*)malloc(sizeof(int) * N*N);

    for(int i=0; i<N*N;i++){
        A[i]=generate_random_value();
    }
    return A;
}

void print_matrix(int N, int * A){

    for (int i=0;i<N;i++){
        for(int j=0;j<N;j++){
            printf("%0f ", A[i*N+j]);
        }
        printf("\n");
    }

    printf("\n");
    printf("\n");
    return;
}


void do_openBLAS_sgemm(int N){


    int * A = generate_random_matrix(N);
    int * B = generate_random_matrix(N);
    int * C = generate_random_matrix(N);

    for (int i=0;i<N;i++){
        for (int j=0;j<N;j++){
            C[i*N+j] = 0.0;
        }
    }


    print_matrix(N, A);
    print_matrix(N, B);
    print_matrix(N, C);

    float FLOPS=2.0*N*N*N;
    float GFLOPS=FLOPS*1e-9;

    printf("Total GFLOPs: %0f\n", GFLOPS);

    float time=0.0;

    //cblas_sgemm(
    //_ __Order: CBLAS_ORDER,
    //_ __TransA: CBLAS_TRANSPOSE,
    //_ __TransB: CBLAS_TRANSPOSE,
    //_ __M: Int32,
    //_ __N: Int32,
    //_ __K: Int32,
    //_ __alpha: Float,
    //_ __A: UnsafePointer<Float>!,
    //_ __lda: Int32,
    //_ __B: UnsafePointer<Float>!,
    //_ __ldb: Int32,
    //_ __beta: Float,
    //_ __C: UnsafeMutablePointer<Float>!,
    //_ __ldc: Int32
    //)
//  cblas_dgemm(CblasColMajor, CblasNoTrans, CblasTrans,3,3,2,1,A, 3, B, 3,2,C,3);

  struct timeval start,finish;
  double duration;

  gettimeofday(&start, NULL);

    cblas_sgemm(
        CblasRowMajor,  //order
        CblasNoTrans,   //transpose
        CblasNoTrans,     //transb
        N,              //M
        N,              //N
        N,              //K
        1,              //alpha
        A,
        N,              //A
        B, 
        N, 
        1, 
        C, 
        N
    );
  
    gettimeofday(&finish, NULL);

    // GENERATE RANDOM MATRIX


    duration = ((double)(finish.tv_sec-start.tv_sec)*1000000 + (double)(finish.tv_usec-start.tv_usec)) / 1000000;

    float GFLOPS_per_sec = (float)(FLOPS)/(float)(duration)*1e-9;

    printf("GFLOPS: %0d\n", GFLOPS_per_sec);
    //print_matrix(N, C);

    free(A);
    free(B);
    free(C);

    return;
}




int main(){

    openblas_set_num_threads(1);    // openBLAS was using all my 12 threads before this call...

    int N=4;

    do_openBLAS_sgemm(N);
}