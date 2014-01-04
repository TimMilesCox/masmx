#include <stdio.h>

typedef struct { char		 *name,
				*flags; } special_flag;

static special_flag		 exceptions[]
	=	{ {	"maxmaxi", "-lnoz"	} ,
		  {	"maxtini", "-lnoz"	} ,
		  {	"maxwini", "-lnoz"	} ,
		  {	 NULL,	   "-lnoy"	} } ;

static char *flags(char *name)
{
   char			*p;
   int			 x = 0;

   while (p = exceptions[x].name)
   {
      if (strcmp(p, name)) x++;
      else return exceptions[x].flags;
   }

   return "-lnoy";
}

int main()
{
   char			 name[24];
   char			*p, *q;
   int			 symbol;


   printf("del ..\\test.o3\\*.*\n");
   printf("del ..\\text.o3\\*.*\n");

   printf("..\\masmx a1 ..\\test.o3\\a2 -z > ..\\text.o3\\a2.txt\n");
   printf("..\\masmx a1 ..\\test.o3\\a3 -c > ..\\text.o3\\a3.txt\n");
   printf("..\\masmx a1 ..\\test.o3\\a4 -zc > ..\\text.o3\\a4.txt\n");

   for (;;)
   {
      p = gets(name);
      if (!p) break;
      
      while(symbol = *p)
      {
         if (symbol == '.') break;
         p++;
      }

      *p = 0;
      q = flags(name);

      printf("..\\masmx %s %s ..\\test.o3\\%s > ..\\text.o3\\%s.txt\n",
             name, q, name, name);
   }

   printf("call ..\\linkpart\n");
   printf("call ..\\coldfire\n");
   printf("call ..\\ppc_kern\n");
   return 0;
}
