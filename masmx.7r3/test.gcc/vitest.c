static int	 one = 1;
int		 two = 2;

int add(int input)
{
   static int	 one = 1;

   int		 two = 2;

   two += input;
   two += one;
   two = adagain_more(two);
   primary_one(two);
   primary_two(two);
   return two;
}

int adagain(int input)
{
   static int    one = 1;

   int           two = 2;

   two += input;
   two += one;
   two = add_more(two);
   primary_three(two);
   primary_four(two);
   return two;
}
