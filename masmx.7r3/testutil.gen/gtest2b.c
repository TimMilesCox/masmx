#include <stdio.h>

typedef struct { char		 *name,
				*flags; } special_flag;

static char			*bypass[]
	=	{	"array",
			"arrayok",
			"ast",
			"avast",
			"avastok",
			"bb",
			"brozzing",
			"capsule",
			"complex",
			"fruit",
			"grig",
			"mango",
			"mbank",
			"mbank1",
			"ocycle",
			"overlaid",
			"overlay",
			"ppc1",
			"ppcsinga",
			"ppcsingb",
			"ppcsingr",
			"ppcuvast",
			"proceds",
			"pusingv",
			"pvusinga",
			"smaragd",
			"smaragd1",
			"smaragd7",
			"space",
			"sterm",
			"transport",
			"trau",
			"tree",
			"trees",
			"twiggy",
			"uart",
			"using",
			"usinga",
			"usingb",
			"usingl",
			"usingpv",
			"usingr",
			"usingv",
			"welblech",
			"wellaugh",
			"wellbad",
			"wellfest",
			 NULL			} ;


static special_flag		 exceptions[]
	=	{ {	"maxmaxi", "-lnoz"	} ,
		  {	"maxtini", "-lnoz"	} ,
		  {	"maxwini", "-lnoz"	} ,
		  {	 NULL,	   "-lnoy"	} } ;

static int skip(char *name)
{
   char			*p;
   int			 x = 0;

   while (p = bypass[x])
   {
      if (strcmp(name, p)) x++;
      else return 1;
   }

   return 0;
}
static char *flags(char *name)
{
   char			*p;
   int			 x = 0;

   while (p = exceptions[x].name)
   {
      if (strcmp(p, name)) x++;
      else return exceptions[x].flags;
   }

   return "-lno";
}

int main()
{
   char			 name[24];
   char			*p, *q;
   int			 symbol;


   printf("del ..\\test.zo3\\*.*\n");
   printf("del ..\\text.zo3\\*.*\n");

   printf("..\\masmx a1 ..\\test.zo3\\a2 -z > ..\\text.zo3\\a2.txo\n");
   printf("..\\masmx a1 ..\\test.zo3\\a3 -c > ..\\text.zo3\\a3.txo\n");
   printf("..\\masmx a1 ..\\test.zo3\\a4 -zc > ..\\text.zo3\\a4.txo\n");

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

      if (skip(name)) continue;
      q = flags(name);

      printf("..\\masmz %s %s ..\\test.zo3\\%s > ..\\text.zo3\\%s.txt\n",
             name, q, name, name);
   }

   return 0;
}
