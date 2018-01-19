
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
using namespace std;

#include <math.h>
#include <GL/glut.h>
#include <GL/gl.h>
#include<stdio.h>
#include<stdlib.h>
#include <time.h>
#include <algorithm>

static GLint imagewidth;
static GLint imageheight;
static GLint pixellength;
static GLubyte* pixeldata;

static GLint imagewidth1;
static GLint imageheight1;
static GLint pixellength1;
static GLubyte* pixeldata1;



#define N 710*512    
#define blocks 710   
#define threads 512  

//CUDA  kernel********************************************************************

__global__ void add(int *a, int *r, int *g, int *b, float *gc)
{

	int i = (blockIdx.x*blockDim.x) + threadIdx.x;

	gc[5120 * 6 + i * 6    ] = b[i] * 0.00390625;
	//gc[5120 * 6 + i * 6    ] = float(b[i]) / 256;
	gc[5120 * 6 + i * 6 + 1] = g[i] * 0.00390625;
	//gc[5120 * 6 + i * 6 + 1] = float(g[i]) / 256;
	gc[5120 * 6 + i * 6 + 2] = r[i] * 0.00390625;
	//gc[5120 * 6 + i * 6 + 2] = float(r[i]) / 256;

	gc[5120 * 6 + i * 6 + 3] = float(i - ((i>>9)<<9) );  // i%512
	//gc[5120 * 6 + i * 6 + 3] = float(i % 512);
	gc[5120 * 6 + i * 6 + 4] = float( i >> 9);
	//gc[5120 * 6 + i * 6 + 4] = float((i - (i % 512)) / 512);
	gc[5120 * 6 + i * 6 + 5] = float(a[i]);
}



float c[6 * N + 5120 * 6] = { 0.0 };
float f[6 * N + 5120 * 6] = { 0.0 };



//openGL******************************************************************


GLint SCREEN_WIDTH = 0;
GLint SCREEN_HEIGHT = 0;

GLint windowWidth = 700;
GLint windowHeight = 700;

GLfloat xRotAngle = 0.0f;

GLfloat yRotAngle = 0.0f;

GLfloat zRotAngle = 0.0f;



void renderScreen(void) {


	//glClearColor(1.0f,1.0f,1.0f,1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

	glPushMatrix();

	glRotatef(xRotAngle, 1.0f, 0.0f, 0.0f);

	glRotatef(yRotAngle, 0.0f, 1.0f, 0.0f);

	glRotatef(zRotAngle, 0.0f, 0.0f, 1.0f);


	glEnable(GL_POINT_SMOOTH);
	glHint(GL_POINT_SMOOTH, GL_NICEST);
	glEnable(GL_LINE_SMOOTH);
	glHint(GL_LINE_SMOOTH, GL_NICEST);



	glColor3f(1.0f, 1.0f, 1.0f);
	glBegin(GL_LINES);
	glVertex3f(-53.0f, 0.0f, 0.0f);
	glVertex3f(53.0f, 0.0f, 0.0f);
	glVertex3f(0.0f, -53.0f, 0.0f);
	glVertex3f(0.0f, 53.0f, 0.0f);
	glVertex3f(0.0f, 0.0f, -53.0f);
	glVertex3f(0.0f, 0.0f, 53.0f);
	glEnd();

	glPushMatrix();
	glTranslatef(53.0f, 0.0f, 0.0f);
	glRotatef(90.0f, 0.0f, 1.0f, 0.0f);
	glutWireCone(10, 20, 10, 10);
	glPopMatrix();

	glPushMatrix();
	glTranslatef(0.0f, 53.0f, 0.0f);
	glRotatef(-90.0f, 1.0f, 0.0f, 0.0f);
	glutWireCone(10, 20, 10, 10);
	glPopMatrix();

	glPushMatrix();
	glTranslatef(0.0f, 0.0f, 53.0f);
	glRotatef(90.0f, 0.0f, 0.0f, 1.0f);
	glutWireCone(10, 20, 10, 10);
	glPopMatrix();




	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(3, GL_FLOAT, 6 * sizeof(GLfloat), &f[0]);
	glVertexPointer(3, GL_FLOAT, 6 * sizeof(GLfloat), &f[3]);
	glPointSize(1);
	glBegin(GL_POINTS);
	for (int i = 0; i<(N + 5120); i++)

		glArrayElement(i);


	glEnd();

	glPopMatrix();

	glutSwapBuffers();
}


void changeSize(GLint w, GLint h) {

	GLfloat ratio;

	GLfloat coordinatesize = 750.0f;

	if ((w == 0) || (h == 0))
		return;

	glViewport(0, 0, w * 1, h * 1);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	ratio = (GLfloat)w / (GLfloat)h;



	glOrtho(-coordinatesize, coordinatesize, -coordinatesize / ratio, coordinatesize / ratio, -coordinatesize, coordinatesize);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}


void specialKey(int key, int x, int y) {

	if (key == GLUT_KEY_UP) {
		xRotAngle -= 5.0f;
	}
	else if (key == GLUT_KEY_DOWN) {
		xRotAngle += 5.0f;
	}
	else if (key == GLUT_KEY_LEFT) {
		yRotAngle -= 5.0f;
	}
	else if (key == GLUT_KEY_RIGHT) {
		yRotAngle += 5.0f;
	}
	else if (key == GLUT_KEY_PAGE_UP) {
		zRotAngle -= 5.0f;
	}
	else if (key == GLUT_KEY_PAGE_DOWN) {
		zRotAngle += 5.0f;
	}

	glutPostRedisplay();
}





int main(int argc, char* argv[]) {

	clock_t start, finish;
	double totaltime;
	start = clock();
	//******************************************************************************

	FILE* pfile = fopen("1.bmp", "rb");
	if (pfile == 0) exit(0);


	fseek(pfile, 0x0012, SEEK_SET);
	fread(&imagewidth, sizeof(imagewidth), 1, pfile);
	fread(&imageheight, sizeof(imageheight), 1, pfile);


	pixellength = imagewidth * 3;
	while (pixellength % 4 != 0)pixellength++;
	pixellength *= imageheight;


	pixeldata = (GLubyte*)malloc(pixellength);
	if (pixeldata == 0) exit(0);
	fseek(pfile, 54, SEEK_SET);
	//cout<<pixellength<<endl;
	fread(pixeldata, pixellength, 1, pfile);
	int shen[N];
	for (int i = 0; i <= N; i++)
		shen[i] = pixeldata[3 * i];


	fclose(pfile);

	//******************************************************************************

	FILE* pfile1 = fopen("2.bmp", "rb");
	if (pfile1 == 0) exit(0);


	fseek(pfile1, 0x0012, SEEK_SET);
	fread(&imagewidth1, sizeof(imagewidth1), 1, pfile1);
	fread(&imageheight1, sizeof(imageheight1), 1, pfile1);
	

	pixellength1 = imagewidth1 * 3;
	while (pixellength1 % 4 != 0)pixellength1++;
	pixellength1 *= imageheight1;


	pixeldata1 = (GLubyte*)malloc(pixellength1);
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

	fclose(pfile1);

	//******************************************************************************


	/*		 c[0]=100;
	c[1]=100;
	c[2]=100;
	c[3]=-10;
	c[4]=-10;
	c[5]=-10;
	*/

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


	int *dev_a = 0;
	int *dev_r = 0;
	int *dev_g = 0;
	int *dev_b = 0;
	float *dev_c = 0;



	cudaMalloc((void**)&dev_a, N * sizeof(int));
	cudaMalloc((void**)&dev_r, N * sizeof(int));
	cudaMalloc((void**)&dev_g, N * sizeof(int));
	cudaMalloc((void**)&dev_b, N * sizeof(int));
	cudaMalloc((void**)&dev_c, 6 * (N + 5120) * sizeof(float));


	cudaMemcpy(dev_a, shen, N * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_r, red, N * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_g, green, N * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_b, blue, N * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_c, c, (N + 5120) * 6 * sizeof(float), cudaMemcpyHostToDevice);

	float time_elapsed=0;
	cudaEvent_t start1;
	cudaEvent_t stop;
	
	cudaEventCreate(&start1);    //創建EVENT
	cudaEventCreate(&stop);

	cudaEventRecord( start1,0);    //紀錄當前時間
	

	//dim3 grid(DIM,DIM);
	add <<< blocks, threads >>>(dev_a, dev_r, dev_g, dev_b, dev_c);

			cudaEventRecord( stop,0);    //紀錄當前時間

	cudaEventSynchronize(start1);    //Waits for an event to complete.
	cudaEventSynchronize(stop);    //Waits for an event to complete.Record之前任務
	cudaEventElapsedTime(&time_elapsed,start1,stop);    //計算時間差
	



	cudaMemcpy(f, dev_c, 6 * (N + 5120) * sizeof(float), cudaMemcpyDeviceToHost);

	//for(int j=24500;j<24576;j++)
	//	cout<<c[j]<<endl;

	cudaFree(dev_a);
	cudaFree(dev_r);
	cudaFree(dev_g);
	cudaFree(dev_b);
	cudaFree(dev_c);

	//cudaEventDestroy(start);    //destory the event
	cudaEventDestroy(stop);

	printf("執行時間%f(ms)\n",time_elapsed);		//cuda執行時間
	

	//openGL顯示部分*****************************************************************



	glutInit(&argc, argv);

	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);

	SCREEN_WIDTH = glutGet(GLUT_SCREEN_WIDTH);

	SCREEN_HEIGHT = glutGet(GLUT_SCREEN_HEIGHT);

	glutCreateWindow("3D HumanFace With CUDA&openGL");

	glutReshapeWindow(windowWidth, windowHeight);

	glutPositionWindow((SCREEN_WIDTH - windowWidth) / 2, (SCREEN_HEIGHT - windowHeight) / 2);

	glutReshapeFunc(changeSize);

	glutDisplayFunc(renderScreen);

	glutSpecialFunc(specialKey);

	finish = clock();
	totaltime = (double)(finish - start) / CLOCKS_PER_SEC;
	cout<<"\n此程序運行時間為"<<totaltime*1000<<"毫秒"<<endl;

	glutMainLoop();



	return 0;


}
