#include <stdio.h>


void PrintVacant(int cycle){
    int cnt;
    for(cnt=0;cnt<cycle;cnt++){
	printf("0_00\n");
    }
}


void PrintPacket(int x_pos, int y_pos){
    int i,a;
    char pos_x[5];
    char pos_y[5];
    sprintf(pos_x,"%04x",x_pos);
    sprintf(pos_y,"%04x",y_pos);
    a = 0;
    int cnt = 0;
    /* Preamble */
    for(cnt = 0;cnt < 7;cnt++){
	printf("1_55 //Preamble\n");
    }
    printf("1_d5 //SFD\n");
    /* L2 Header */
    cnt = 0; 
    for(cnt = 0; cnt < 6; cnt++){
	printf("1_ff //Ether : Dest MAC\n");
    }
    cnt = 0;
    for(cnt = 0; cnt < 6; cnt++){
	printf("1_ee //Ether : Dest MAC\n");
    }
    printf("1_08 //Ether : Type (IPv4 = 0x0800)\n");
    printf("1_00\n");
    /* L3 Header */ 
    printf("1_45 //IP : Version(4), Header Length(20)\n");
    printf("1_00 //IP : DSF\n");
    printf("1_03 //IP : Total Length(992)\n");
    printf("1_e0\n");
    printf("1_01 //IP : Identification(0x0123)\n");
    printf("1_23\n");
    printf("1_40 //IP : Flags\n");
    printf("1_00\n");
    printf("1_40 //IP : TTL\n");
    printf("1_11 //IP : Protocol\n");
    printf("1_8f //IP : Checksum\n");
    printf("1_c8\n");
    printf("1_0a //IP : Source IP Address\n");
    printf("1_00\n");
    printf("1_15\n");
    printf("1_63\n");
    printf("1_c0 //IP : Dest IP Address\n");
    printf("1_a8\n");
    printf("1_00\n");
    printf("1_01\n");
    /* UDP header */
    printf("1_98 //UDP : Source Port (0x9869 = 39017)\n");
    printf("1_69\n");
    printf("1_30 //UDP : Dest Port (0x3039 = 12345)\n");
    printf("1_39\n");
    printf("1_03 //UDP : Length(0x03cc = 972)\n");
    printf("1_cc\n");
    printf("1_42 //UDP : Checksum\n");
    printf("1_4a\n");
    /* Data  X,Y posision (Start Point)*/
    printf("1_%c%c //PositionY\n",pos_y[2],pos_y[3]);
    printf("1_%c%c //PositionY\n",pos_y[0],pos_y[1]);
    printf("1_%c%c //PositionX\n",pos_x[2],pos_x[3]);
    printf("1_%c%c //PositionX\n",pos_x[0],pos_x[1]);
    /* Data YUV color DATA segment */
    for(i=0;i<640;i++){
	if(a>253) a = 0;
	printf("1_%02x // DATA[%d] : Green\n",a,i);
	a++;
	printf("1_%02x // DATA[%d] : Red\n",a,i);
    	a++;
    }
    printf("1_11 // FCS\n");
    printf("1_22 // FCS\n");
    printf("1_33 // FCS\n");
    printf("1_44 // FCS\n");
}

int main(){
    /* Initial Vacant Period */
    PrintVacant(1260);

    int linecnt,frame;
    /* Generate Packet for Frame */
    for(frame=0;frame<4;frame++){
    	for(linecnt=0;linecnt<720;linecnt++){
		PrintPacket(0,linecnt);
		/* Minumum IFG == 14 */
		PrintVacant(14);
		PrintPacket(640,linecnt);
		/* Vacant Period per Horizontal Active Line */
		/* Period is 4958ns = 620cycle */
		PrintVacant(75);
    	}
    	/* Vacant Period per Vertical Active Line */
    	/* 30line == 663300ns == 82912cycle */
    	PrintVacant(82912);
    }

    return 0;
}
