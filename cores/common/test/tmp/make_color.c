#include <stdio.h>

int main(){
    int i,a;
    a = 0;
    for(i=0;i<640;i++){
	if(a>253) a = 0;
	//printf("1_%02x // DATA[%d] : Blue\n",a,i);
	//a++;
	printf("1_%02x // DATA[%d] : Green\n",a,i);
	a++;
	printf("1_%02x // DATA[%d] : Red\n",a,i);
    	a++;
    }

    return 0;
}
