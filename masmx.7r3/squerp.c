#include <stdio.h>

#define BANK    262144
#define FACTOR  11
#define XS      (BANK/FACTOR*7/4)

int main()
{
   int		 locator = -1,
		 address = -2,
		 integer = -3;

   int		 xs = 0;
   int		 x;

   char		 data[36];
   char		*p;

   p = fgets(data, 36, stdin);

   p = fgets(data, 36, stdin);

   if (!p)
   {
      printf("index %x data missing\n", xs);
      return 0;
   }

   if (*p ^ '$')
   {
      printf("index %x sentinel %x\n", xs, *p);
      return 0;
   }

   x = sscanf(p + 1, "%d:%x", &locator, &address);

   if (x ^ 2)
   {
      printf("index %x fields %x\n", xs, x);
      return 0;
   }

   if (locator ^ 6)
   {
      printf("index %x locator %x\n", xs, locator);
      return 0;
   }

   if (address ^ 0x6000 + xs) 
   {
      printf("index %x address %x\n", xs, address);
      return 0;
   }

   while (xs++ < XS)
   {
      x = scanf("%x", &integer);

      if (x ^ 1)
      {
         printf("index %x values %x\n", xs, x);
         break;
      }

      if (integer ^ xs) 
      {
         printf("index %x integer %x\n", xs, integer);
         break;
      }
   }

   p = fgets(data, 36, stdin);
   if (p == NULL) printf("index %x final data missing\n", xs);

   x = scanf("$%d:%x %x", &locator, &address, &integer);
   if (x ^ 3)            printf("final index %x fields %x\n",  xs, x);
   if (locator ^ 5)      printf("final index %x locator %x\n", xs, locator);
   if (address ^ 0x5000) printf("final index %x address %x\n", xs, address);
   if (integer ^ xs)     printf("final index %x integer %x\n", xs, integer);

   return 0;
}

