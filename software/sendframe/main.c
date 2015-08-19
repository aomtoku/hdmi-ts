/* include file for standard library for C */
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

/* include file for socket communication */
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

/* include file for FrameBuffer */
#include <sys/ioctl.h>
#include <linux/fb.h>
#include <linux/fs.h>
#include <sys/mman.h>

#include "send.h"

/* define the Parameter */
#define DEVICE_NAME "/dev/fb0"

#define VGA_X 640
#define VGA_Y 480

#define DATA_SIZE 960
#define RGB_BYTE 3
#define BIT 8
#define RED_DEC 2145386496


/* Debug Parameter */
//#define DEBUG_RED_DISP
#define NODEBUG

/*GLOBAL VARIBLE*/
int options;

/* Struct for Packet DataGrum */
struct packet{
    short int xres_screen;
    short int yres_screen;
    unsigned char color[DATA_SIZE];
};

int udpconnect(char *name, int port){
    int s;
    int gai;
    struct addrinfo hints, *res, *res0;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_protocol = IPPROTO_UDP;

    char service[32];
    sprintf(service, "%d", port);
    gai = getaddrinfo(name, service, &hints, &res0);
    if(gai!=0){
	fprintf(stderr,"getaddrinfo: %s\n", gai_strerror(gai));
	exit(1);
    }

    for(res=res0; res!=NULL; res=res->ai_next){
	s = socket(res->ai_family,res->ai_socktype, res->ai_protocol);
	if(s < 0) continue;
	if(connect(s,res->ai_addr, res->ai_addrlen) < 0){
	    close(s);
	    s = -1;
	    continue;
	}
	break;
    }

    freeaddrinfo(res0);

    if(s < 0){
	fprintf(stderr, "cannot connect\n");
	exit(1);
    }

    return s;
}

void SendPacket(int fd,int s, int bpp, int line_len,struct fb_var_screeninfo vinfo, struct fb_fix_screeninfo finfo, char *fbptr){

    int x = 0;
    int y = 0;
    long int location;
    struct packet packet_udp;
    packet_udp.xres_screen = x; 
    packet_udp.yres_screen = y; 
    int ycnt=0;
    int cnt = 0;
    int snd;
    
    while(1){
    for(y=0;y<VGA_Y;y++){
	for(x=0;x<VGA_X;x++){
	    location = ((x+vinfo.xoffset)*bpp/8) + (y+vinfo.yoffset)* line_len;
	    if(cnt == 319){
#ifdef DEBUG_RED_DISP
		memcpy(packet_udp.color+(cnt*RGB_BYTE), num,sizeof(unsigned int *) );
#else
		memcpy(packet_udp.color+(cnt*RGB_BYTE), (char *)(fbptr+location), sizeof(unsigned int *));
#endif
		if(x == VGA_X - 1) {
		    packet_udp.xres_screen = VGA_X/2;
		    packet_udp.yres_screen = y;
		} else {
		    packet_udp.xres_screen = 0; 
		    packet_udp.yres_screen = y;
		}
		
		/* Recvfrom gets a packet for UDP with returning error*/
		do {
		    snd = send(s, &packet_udp, sizeof(struct packet), 0);
		} while( snd < 0 && (errno == EAGAIN || errno == EWOULDBLOCK ));

		if(send < 0){
		    fprintf(stderr,"cannot send a packet \n");
		    exit(1);
		}

		cnt = 0;
	    } else {
#ifdef DEBUG_RED_DISP
		memcpy(packet_udp.color+(cnt*RGB_BYTE), num,sizeof(unsigned int *) );
#else
		memcpy(packet_udp.color+(cnt*RGB_BYTE), fbptr+location, sizeof(unsigned int *));
#endif		
		cnt++;
	    }
	}
	ycnt++;
    }
    }
}


/**********************::
 * option 
 * usage: sendframe [-f ]
 *
 *
 * *********************/


int main(int argc, char **argv){

    /*check the augment */
    if(argc < 3){
	fprintf(stderr, "usage : ./a.out <hostname> <port>\n");
	exit(1);
    }

    int ch;
    while((ch = getopt(argc, argv, "dn:")) != EOF) {
	switch(ch){
	    case 'n':
	    		break;
	    case 'd':   options |= DEBUG_MODE;
	    		//printf("option = %02x\n",options);
	    default :
	    		break;
	}
    }
    
    /* open network socket */
    int port = atoi(argv[2]);
    int s;
    s = udpconnect(argv[1],port);

    /* FrameBuffer */
    int fd, screensize;

    fd = open(DEVICE_NAME, O_RDWR);
    if(!fd){
	fprintf(stderr, "cannot open the FrameBuffer '/dev/fb0' \n");
	exit(1);
    }

    struct fb_var_screeninfo vinfo;
    struct fb_fix_screeninfo finfo;

    if(ioctl(fd,FBIOGET_FSCREENINFO, &finfo)){
	fprintf(stderr, "cannot fix info\n");
	exit(1);
    }
    if(ioctl(fd,FBIOGET_VSCREENINFO, &vinfo)){
	fprintf(stderr, "cannot variable info\n");
	exit(1);
    }
    int xres,yres,bpp,line_len;
    xres = vinfo.xres;  yres = vinfo.yres;  bpp = vinfo.bits_per_pixel; 
    line_len = finfo.line_length;
    
    /* Check your machine's resolusion and pixel line length(bytes) */
    printf("%d(pixel)x%d(line), %d(bit per pixel), %d(line length)\n",xres,yres,bpp,line_len);
    screensize = xres * yres * bpp/BIT;

    /*memory I/O */
    char *fbptr;

    fbptr = (char *)mmap(0,screensize,PROT_READ | PROT_WRITE, MAP_SHARED,fd,0);
    if((int)fbptr == -1){
	fprintf(stderr,"cannot get framebuffer\n");
	exit(1);
    }
printf("the frame buffer device was mapped\n");

#ifdef DEBUG_RED_DISP
    unsigned int *num;
    num = (unsigned int  *)malloc(sizeof(unsigned int *));
    *num = RED_DEC;
#endif
    SendPacket(fd,s,bpp,line_len, vinfo,finfo,fbptr);
    
    munmap(fbptr,screensize);
    
    /* close the filediscriptor of socket */
    close(s);
    close(fd);

    return 0;
}

