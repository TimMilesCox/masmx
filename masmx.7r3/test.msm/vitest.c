static int	 one = 1;
int		 two = 2;

int add(int input)
{
   static int	 one = 1;

   int		 two = 2;

   two += input;
   two += one;
   return two;
}

int adagain(int input)
{
   static int    one = 1;

   int           two = 2;

   two += input;
   two += one;
   return two;
}
