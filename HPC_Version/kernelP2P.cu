
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
using namespace std;

#include <math.h>
//#include <GL/glut.h>
//#include <GL/gl.h>
#include<stdio.h>
#include<stdlib.h>
#include <time.h>
#include <algorithm>
#include "timer.h"

static int imagewidth;
static int imageheight;
static int pixellength;
static unsigned char* pixeldata;

static int imagewidth1;
static int imageheight1;
static int pixellength1;
static unsigned char* pixeldata1;



#define N 710*512    //图像分辨率
#define blocks 710   //圖像高度
#define threads 512  //圖像寬度





//CUDA  kernel函數********************************************************************

__global__ void add(int *a, int *r, int *g, int *b, float *gc)
{

	int i = (blockIdx.x*blockDim.x) + threadIdx.x;

	gc[5120 * 6 + i * 6    ] = b[i] * 0.00390625;
	//gc[5120 * 6 + i * 6    ] = float(b[i]) / 256;
	gc[5120 * 6 + i * 6 + 1] = g[i] * 0.00390625;
	//gc[5120 * 6 + i * 6 + 1] = float(g[i]) / 256;
	gc[5120 * 6 + i * 6 + 2] = r[i] * 0.00390625;
	//gc[5120 * 6 + i * 6 + 2] = float(r[i]) / 256;

//	gc[5120 * 6 + i * 6 + 3] = float(i - ((i>>9)<<9) );  // i%512
	//gc[5120 * 6 + i * 6 + 3] = float(i % 512);
//	gc[5120 * 6 + i * 6 + 4] = float( i >> 9);
	//gc[5120 * 6 + i * 6 + 4] = float((i - (i % 512)) / 512);
//	gc[5120 * 6 + i * 6 + 5] = float(a[i]);
}




__global__ void add2(int *a, int *r, int *g, int *b, float *gc)
{

        int i = (blockIdx.x*blockDim.x) + threadIdx.x;

//       gc[5120 * 6 + i * 6    ] = b[i] * 0.00390625;
        //gc[5120 * 6 + i * 6    ] = float(b[i]) / 256;
//        gc[5120 * 6 + i * 6 + 1] = g[i] * 0.00390625;
        //gc[5120 * 6 + i * 6 + 1] = float(g[i]) / 256;
//        gc[5120 * 6 + i * 6 + 2] = r[i] * 0.00390625;
        //gc[5120 * 6 + i * 6 + 2] = float(r[i]) / 256;

        gc[5120 * 6 + i * 6 + 3] = float(i - ((i>>9)<<9) );  // i%512
        //gc[5120 * 6 + i * 6 + 3] = float(i % 512);
        gc[5120 * 6 + i * 6 + 4] = float( i >> 9);
        //gc[5120 * 6 + i * 6 + 4] = float((i - (i % 512)) / 512);
        gc[5120 * 6 + i * 6 + 5] = float(a[i]);
}



float c[6 * N + 5120 * 6] = { 0.0 };
float f[6 * N + 5120 * 6] = { 0.0 };


int main(int argc, char* argv[]) {

	clock_t start, finish;
	//double totaltime;
	start = clock();
	//******************************************************************************

	//讀深度圖
	FILE* pfile = fopen("1.bmp", "rb");
	if (pfile == 0) exit(0);

	//讀取圖像大小
	fseek(pfile, 0x0012, SEEK_SET);
	fread(&imagewidth, sizeof(imagewidth), 1, pfile);
	fread(&imageheight, sizeof(imageheight), 1, pfile);

	//計算像素數據長度
	pixellength = imagewidth * 3;
	while (pixellength % 4 != 0)pixellength++;
	pixellength *= imageheight;

	//讀取像素數據
	pixeldata = (unsigned char*)malloc(pixellength);
	if (pixeldata == 0) exit(0);
	fseek(pfile, 54, SEEK_SET);
	//cout<<pixellength<<endl;
	fread(pixeldata, pixellength, 1, pfile);
	int shen[N];
	for (int i = 0; i <= N; i++)
		shen[i] = pixeldata[3 * i];

	//關閉文件
	fclose(pfile);

	//******************************************************************************

	//讀取亮度
	FILE* pfile1 = fopen("2.bmp", "rb");
	if (pfile1 == 0) exit(0);

	//讀取圖片大小
	fseek(pfile1, 0x0012, SEEK_SET);
	fread(&imagewidth1, sizeof(imagewidth1), 1, pfile1);
	fread(&imageheight1, sizeof(imageheight1), 1, pfile1);
	
	//計算數據長度
	pixellength1 = imagewidth1 * 3;
	while (pixellength1 % 4 != 0)pixellength1++;
	pixellength1 *= imageheight1;

	//讀取像素數據
	pixeldata1 = (unsigned char*)malloc(pixellength1);
	if (pixeldata1 == 0) exit(0);
	fseek(pfile1, 54, SEEK_SET);
	//cout<<pixellength<<endl;
	fread(pixeldata1, pixellength1, 1, pfile1);
	int red[N];
	int green[N];
	int blue[N];

	for (int i = 0; i <= N; i++)
	{
		red[i] = pixeldata1[3 * i];
		green[i] = pixeldata1[3 * i + 1];
		blue[i] = pixeldata1[3 * i + 2];
	}
	//關閉文件
	fclose(pfile1);

	//******************************************************************************

	//修補圖片
	int num = 0;
	for (int yo = 220; yo <= 390; yo++)//220,300
	{
		for (int xo = 212; xo <= 292; xo++)//212,292
		{
			if (shen[512 * yo + xo] == 0)	//如果深度=0  說明厝為了
			{

				for (int a = xo; a <= xo + 20; a++)
				{
					num++;					//一行一行找 紀錄缺失的總pixel
					if (shen[a + 512 * yo] != 0)
					{

						break;
					}
				}

				for (int r = 0; r<num; r++)	//對每一行 做線性修補
					shen[512 * yo + xo + r] = (shen[512 * yo + xo + r - 1] + shen[512 * yo + xo + r - 512]) / 2;

			}

		}
	}





	//******************************************************************************
	//深度圖缺失了
	int z1 = 0; int xbz = 0; int ybz = 0;
	for (int y0 = 220; y0 <= 390; y0++)//220,300
	{
		for (int x0 = 212; x0 <= 292; x0++)//212,292
		{
			if (shen[y0 * 512 + x0]>z1)//512
			{
				xbz = x0;
				ybz = y0;
				z1 = shen[y0 * 512 + x0];//512
			}
		}
	}

	int x1 = xbz - 90;//90
	int x2 = xbz + 90;
	int y1 = ybz - 90;
	int y2 = ybz + 90;
	cout << xbz << " " << 711 - ybz << endl;//513







	int s = 0; int n = 0, m = 0, j = 0, q = 0, k = 0;

	for (int y = y1; y <= y2; y++)
	{
		for (int x = x1; x <= x2; x++)
		{

			n = shen[y * 512 + x];//512
			m = shen[y * 512 + x + 1];
			j = blue[y * 512 + x + 1024];//b
			q = green[y * 512 + x + 1024];//g
			k = red[y * 512 + x + 1024];//r
			if (abs(n - m) >= 4)//4
								//if(abs(m-n)>=5&&abs(m-n)<=20)
			{
				for (int p = 1; p <= (abs(n - m) - 1); p++)
				{
					c[s * 6] = float(j) / 256;
					c[s * 6 + 1] = float(q) / 256;
					c[s * 6 + 2] = float(k) / 256;
					c[s * 6 + 3] = float(x);
					c[s * 6 + 4] = float(y);
					c[s * 6 + 5] = float(max(n, m) - p);


					s++;


				}
			}
		}
	}













	//CUDA計算部分*******************************************************************
	


        struct stopwatch_t* timerA1 = NULL;
	struct stopwatch_t* timerA2 = NULL;
	struct stopwatch_t* timerA3 = NULL;
        long double compA;
	long double commA1;
	long double commA2;
        /* initialize timer */
        stopwatch_init ();
        timerA1 = stopwatch_create ();
	timerA2 = stopwatch_create ();
	timerA3 = stopwatch_create ();


	int *dev_a = 0;
	int *dev_r = 0;
	int *dev_g = 0;
	int *dev_b = 0;
	float *dev_c = 0;

/*
        int *dev_a2 = 0;
        int *dev_r2 = 0;
        int *dev_g2 = 0;
        int *dev_b2 = 0;
        float *dev_c2 = 0;
*/
	int GPU_A = 0;
	int GPU_B = 1;


	cudaSetDevice(GPU_A);

	cudaMalloc((void**)&dev_a, (N) * sizeof(int));
stopwatch_start (timerA1);
	cudaMalloc((void**)&dev_r, (N) * sizeof(int));
	cudaMalloc((void**)&dev_g, (N) * sizeof(int));
	cudaMalloc((void**)&dev_b, (N) * sizeof(int));
	cudaMalloc((void**)&dev_c, 6 * (N + 5120) * sizeof(float));


	cudaMemcpy(dev_a, shen, (N) * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_r, red,  (N) * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_g, green, (N) * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_b, blue, (N) * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_c, c, (N + 5120) * 6 * sizeof(float), cudaMemcpyHostToDevice);

	commA1 = stopwatch_stop (timerA1);

	stopwatch_start (timerA2);
	add <<< blocks, threads >>>(dev_a, dev_r, dev_g, dev_b, dev_c);
	compA = stopwatch_stop (timerA2);

	stopwatch_start (timerA3);
	cudaMemcpy(f, dev_c, 6 * (N + 5120) * sizeof(float), cudaMemcpyDeviceToHost);	

	cudaFree(dev_a);
	cudaFree(dev_r);
	cudaFree(dev_g);
	cudaFree(dev_b);
	cudaFree(dev_c);

	commA2 = stopwatch_stop (timerA3) + commA1;


        int accessible = 0;
        cudaDeviceCanAccessPeer(&accessible, GPU_B, GPU_A);

        if(accessible){
                cudaSetDevice(GPU_B);
                cudaDeviceEnablePeerAccess(GPU_A,0);
	 	add2 <<< blocks, threads >>>(dev_a, dev_r, dev_g, dev_b, dev_c);
        }












        printf ("Computation time on GPU_A is: %Lg secs\n", compA);
	printf ("Communication time on GPU_A is: %Lg secs\n", commA2);






	return 0;


}
