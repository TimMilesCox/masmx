#include <stdio.h>

#define	BANK	262144
#define	FACTOR	11
#define	XS	(BANK/FACTOR*7/4)

int main()
{
   int		 xs = 0;

   printf("malp*\t$proc\t$(6)\n");
   printf("\t+\tmalp(1,1)\n");
   printf("\t$end\n");

   printf("malfun*\t$func\t*\n");
   while (xs++ < XS) printf("\tmalp\t%d\n", xs);
   printf("\t$return\t%d\n", xs);
   printf("\t$end\n");
   return 0;
}

