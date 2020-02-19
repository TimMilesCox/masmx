#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[])
{
   char	 data[160];
   char	 name[160];
   char	 expression[160];

   int	 x, counter, address;
   int	 all_names = 0;
   char	*p;
   char	*q = "";


   x = argc;   

   while (x--)
   {
      /************************************************************
		the first one is this program name
      ************************************************************/

      if (x == 0) break;

      if (strcmp(argv[x], "all") == 0) all_names = 1;
      else q = argv[x];
   }

   for (;;)
   {
      p = fgets(data, 160, stdin);
      if (p == NULL) break;

      if (data[0] == '+')
      {
         x = sscanf(data + 1, "%[^:]:%s", name, expression);

         if (expression[0] == '$')
         {
            /*******************************************************
		the label is associated with a memory location
		and may be filtered out or in
            *******************************************************/

            if (all_names == 0) continue;
            sscanf(expression+1, "%x:%x", &counter, &address);
         }
         else sscanf(expression, "%x", &address);

         printf("%s %s=%d\n", q, name, address);
      }
   }

   return 0;
}

