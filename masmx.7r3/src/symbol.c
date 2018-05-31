#include <stdio.h>
int main(int argc, char *argv[])
{
   char	 data[72];
   char	 name[60];
   int	 x;
   char	*p;
   char	*q = "";

   if (argc > 1) q = argv[1];

   for (;;)
   {
      p = fgets(data, 71, stdin);
      if (p == NULL) break;

      if (data[0] == '+')
      {
         sscanf(data + 1, "%[^:]:%x", name, &x);
         printf("%s %s=%d\n", q, name, x);
      }
   }

   return 0;
}
