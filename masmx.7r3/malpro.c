#include <stdio.h>

#define	BANK	262144
#define	FACTOR	11

#define	XS	(BANK/FACTOR*7/4)

int main()
{
   int		 xs = 0;

   printf("malp*\t$proc\t$(6)\n");
   while (xs++ < XS) printf("\t+\t%d\n", xs);
   printf("\t$end\n");
   printf("malpro*\t$func\t*\n");
   printf("\tmalp\n");
   printf("\t$return\t%d\n", xs);
   printf("\t$end\n");
   return 0;
}

