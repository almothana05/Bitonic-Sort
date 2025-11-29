#include<bits/stdc++.h>
#include <cuda_runtime.h> 
using namespace std;
mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());
int rnd(int x, int y) {
    return uniform_int_distribution<int>(x, y)(rng);
}

__global__ void sort_it(int *d_arr, int stage, int step, int array_size, int reverse){
    int i = threadIdx.x + blockDim.x * blockIdx.x;
    if(i >= array_size){
        return;
    }

    int dist = (1 << (stage - step)); 
    int active = (i / dist) % 2 == 0; 
    int ascending = ((i / (1 << stage)) % 2 == 0) ^ reverse; 

    if(active && (ascending ^ (d_arr[i] < d_arr[i + dist]))){
        int numm = d_arr[i];
        d_arr[i] = d_arr[i + dist];
        d_arr[i + dist] = numm;
    }
}


vector<int> sortBitonic(int n, vector<int> v, int reverse){
    int bit_count = (32 - __builtin_clz(n)); 
    int new_size =  1 << bit_count; 
    int log_new_size = bit_count;
    if(n == 1 << (bit_count - 1) ){
        new_size = n;
        log_new_size = bit_count - 1;
    }
    int arr[new_size];
    int maxi = INT_MAX;

    for(int i = 0 ; i < n ; i++){
        arr[i] = v[i];
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
            sort_it<<<blocks, threads>>>(d_arr, stage, step, new_size, reverse);
            cudaDeviceSynchronize();

        }
    }

    cudaMemcpy(arr, d_arr, size, cudaMemcpyDeviceToHost);
    cudaFree(d_arr);

    vector<int> u(n);
    for(int x = 0 ; x < n ; x++){
        u[x] = arr[x];
    }
    return u;
}

int main(){
    int number_of_tests = 100;// adjustable
    for(int i = 1 ; i <= number_of_tests ; i++){
        cout << "Test " << i << ": ";
    
        int n = rnd(1 , 100000); // adjustable
        vector<int> v(n);
        for(int i = 0 ; i < n; i++){
            v[i] = rnd(-1000000000, 1000000000); // adjustable
        }
        int reverse = rnd(0, 1);
        vector<int> u = sortBitonic(n , v, reverse);
        sort(v.begin(), v.end());
        if(reverse){
            reverse(v.being(), v.end());
        }

    if(u == v){
            cout << "Passed \n";
        }
        else{
            cout << "Failed \n";
        }
    }
    
}