#define YIELD asm("sc");

static int x = 99;

void idle()
{
   for (;;)
   {
      if (x) x--;
      YIELD
   }
}
