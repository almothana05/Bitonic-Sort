#include<bits/stdc++.h>
#include <cuda_runtime.h> 
using namespace std;


__global__ void sort_it(int *d_arr, int stage, int step, int array_size){
    int i = threadIdx.x + blockDim.x * blockIdx.x;
    if(i >= array_size){
        return;
    }

    int dist = (1 << (stage - step)); // distance between the two swapped elements
    int active = (i / dist) % 2 == 0; // checks if the current element is active
    bool ascending = (i / (1 << stage)) % 2 == 0; // checks weither the current element is in an ascending sort 

    // (ascending ^ (d_arr[i] < d_arr[i + dist])) we are going to swap either if the two condition are not equal therefore we use xor
    if(active && (ascending ^ (d_arr[i] < d_arr[i + dist]))){
        int numm = d_arr[i];
        d_arr[i] = d_arr[i + dist];
        d_arr[i + dist] = numm;
    }
}

int main(){
    int n;
    cin >> n;

    int bit_count = (32 - __builtin_clz(n)); // number of bits used in n
    // (1 << x) is 1 left shift x which gets 2^x
    int new_size =  1 << (bit_count - (n == (1 << (bit_count - 1)))); // size after padding 2^bit_count except when n is a power of 2 (n == (1 << bit_count - 1)) then no padding needed
    int log_new_size = bit_count - (n == (1 << (bit_count - 1)));

    int arr[new_size];
    int maxi = INT_MAX;

    for(int i = 0 ; i < n ; i++){
        cin >> arr[i];
    }

    for(int i = n ; i < new_size ; i++){
        arr[i] = maxi;
    }

    int size = new_size * sizeof(int);
    int *d_arr;

    cudaMalloc((void **)&d_arr, size);
    cudaMemcpy(d_arr, arr, size, cudaMemcpyHostToDevice);

    int threads = 1024;// older gpu's might need 512
    int blocks = (new_size + threads - 1)/threads; // (new_size / threads) using ceil division


    for(int stage = 1 ; stage <= log_new_size ; stage++){
        for(int step = 1 ; step <= stage ; step++){
            sort_it<<<blocks, threads>>>(d_arr, stage, step, new_size);
            cudaDeviceSynchronize();
        }
    }

    cudaMemcpy(arr, d_arr, size, cudaMemcpyDeviceToHost);
    cudaFree(d_arr);

    
}