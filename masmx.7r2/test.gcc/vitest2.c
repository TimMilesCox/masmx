static int	 one = 1;
int		 two_more = 2;

int add_more(int input)
{
   static int	 one = 1;

   int		 two = 2;

   two += input;
   two += one;
   two = adagain(two);
   primary_five(two);
   primary_six(two);
   return two;
}

int adagain_more(int input)
{
   static int    one = 1;

   int           two = 2;

   two += input;
   two += one;
   two = add(two);
   primary_seven(two);
   primary_eight(two);
   return two;
}
