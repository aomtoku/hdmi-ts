#include <stdio.h>


void HBackPorch(int vsyn){
    int cnt;
    for(cnt=0;cnt<110;cnt++){
	printf("%d_0_000000 //Horizontal Back Portch[%d]\n",vsyn,cnt);
    }
}


void HPulseWidth(int vsyn){
    int cnt;
    for(cnt=0;cnt<40;cnt++){
	printf("%d_1_000000 //Horizontal Pulse Width[%d]\n",vsyn,cnt);
    }
}


void HFrontPorch(int vsyn){
    int cnt;
    for(cnt=0;cnt<220;cnt++){
	printf("%d_0_000000 //Horizontal Pulse Widhth[%d]\n",vsyn,cnt);
    }
}

void HActiveVideo(int on, int vsyn){
    int cnt;
    int color = 0;
    for(cnt=0;cnt<1280;cnt++){
	if(color == 256)
	    color = 0;
	if(on)
	    printf("0_0_%02x%02x%02x // Horizontal Active Pixel[%d]\n",color,color,color,cnt);
	else
	    printf("%d_0_000000 // Horizontal No Active[%d]\n",vsyn,cnt);
	color++;
    }
}


void VBackPorch(void){
    int cnt;
    int vsyn = 0;
    for(cnt=0;cnt<5;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(0,vsyn);
    }
}


void VPulseWidth(void){
    int cnt;
    int vsyn = 1;
    for(cnt=0;cnt<5;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(0,vsyn);
    }
}

void VFrontPorch(void){
    int cnt;
    int vsyn = 0;
    for(cnt=0;cnt<20;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(0,vsyn);
    }
}


void VActiveLine(void){
    int cnt;
    int vsyn = 0;
    for(cnt=0;cnt<720;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(1,vsyn);
    }
}

int main(){
    int i;
    for(i=0;i<2;i++){
    	VBackPorch();
    	VPulseWidth();
    	VFrontPorch();
    	VActiveLine();
    }
    return 0;
}
