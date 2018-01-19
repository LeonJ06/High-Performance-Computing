
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
using namespace std;


#include <gl/glut.h>

#define FileName "1.bmp"
static GLint imagewidth;
static GLint imageheight;
static GLint pixellength;
static GLubyte* pixeldata;
#include<stdio.h>
#include<stdlib.h>

int hui[4096];

int BMP()
{

 FILE* pfile=fopen("1.bmp","rb");
 if(pfile == 0) exit(0);

 fseek(pfile,0x0012,SEEK_SET);
 fread(&imagewidth,sizeof(imagewidth),1,pfile);
 fread(&imageheight,sizeof(imageheight),1,pfile);

 pixellength=imagewidth*3;
 while(pixellength%4 != 0)pixellength++;
 pixellength *= imageheight;

 pixeldata = (GLubyte*)malloc(pixellength);
 if(pixeldata == 0) exit(0);
 fseek(pfile,1078,SEEK_SET);
 cout<<pixellength<<endl;
 fread(pixeldata,pixellength,1,pfile);
  
for(int i=0;i<=4095;i++)
	hui[i]=pixeldata[i];
for(int j=3900;j<=4095;j++)
	cout<<hui[j]<<endl;



 fclose(pfile);

 return 0;
}




#define N 256

		__global__ void add(int *a,int *b)
		{int i=threadIdx.x;
		if(i<N)
			b[i*3]=i%64;
			b[i*3+1]=i/64;
			b[i*3+2]=a[i];
		}

	int main(){
		int a[N],b[3*N];
		int *dev_a=0;
		int *dev_b=0;
		for(int i=0;i<N;i++)
				{
					a[i]=hui[i];

					
				}
		cudaMalloc((void**)&dev_a,N*sizeof(int));
		cudaMalloc((void**)&dev_b,3*N*sizeof(int));


		

		cudaMemcpy(dev_a,a,N*sizeof(int),cudaMemcpyHostToDevice);


		add<<<1,N>>>(dev_a,dev_b);

		cudaMemcpy(b,dev_b,3*N*sizeof(int),cudaMemcpyDeviceToHost);

		//for(int j=0;j<3*N;j++)
		//	cout<<b[j]<<endl;
		cudaFree(dev_a);
		cudaFree(dev_b);


		return 0;}

