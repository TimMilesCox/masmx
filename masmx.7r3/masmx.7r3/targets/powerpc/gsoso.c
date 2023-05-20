extern int	 factor;
extern int	 adjustment(int *where);

int		 clanjamfrie = 55;

static int	 yasimi = 99;
static int	 startfromhere;
static int	*cu = &startfromhere;

int soso()
{
   static int	 separate_static_item = 0xa5a5a5a5;
   static long long clearly_so;

   int		 x = startfromhere++;

   x *= factor;
   x += adjustment(cu);
   x -= yasimi;
   return x;
}
