static void flagp1(char *k)
{
   if (pass) return;
   if (!k) return;
   printf("Error: %s Line %d: %s\n", 
	   file_label[depth]->l.name,
	   ll[depth],
	   k);
   ecount++;
}

static void flag(char *k)
{
   if (!pass) return;
   if (!k) return;
   printf("Error: %s Line %d: %s\n", 
	   file_label[depth]->l.name,
	   ll[depth],
	   k);
   ecount++;
}

static void flagp1p(char *n, char *k)
{
   if (pass) return;
   if (!k) return;
   printf("Error: %s Line %d: %s %s\n",
           file_label[depth]->l.name,
           ll[depth],
           n,
           k);
   ecount++;
}

static void flagp(char *n, char *k)
{
   if (!pass) return;
   if (!k) return;
   printf("Error: %s Line %d: %s %s\n",
           file_label[depth]->l.name,
           ll[depth],
           n,
           k);
   ecount++;
}


static void flag_either_pass(char *name, char *k)
{
   printf("Error: %s Line %d: %s %s\n",
           file_label[depth]->l.name,
           ll[depth],
           name,
           k);
   ecount++;
}

#ifdef CLEATING
static void cleat()
{
   flag_either_pass("macro", "line zero length\nabandon");
   exit(0);
}
#endif

static void flagf(char *k)
{
   if (selector['f'-'a']) flagp1(k);
   flag(k);
}

static void flagg(char *k)
{
   if (!selector['g'-'a']) flagp1(k);
   flag(k);
}

static void uflag(char *k)
{
   if (!pass) return;
   if (skipping) return;

   if (!selector['U'-'A']) return;

   printf("undefined name in %s on Line %d: %s\n", 
	   file_label[depth]->l.name,
	   ll[depth],
	   k);
}

static void notep1(char *k)
{
   if (pass) return;
   if (!k) return;
   printf("Note: %s Line %d: %s\n", 
	   file_label[depth]->l.name,
	   ll[depth],
	   k);
}

static void notep1p(char *n, char *k)
{
   if (pass) return;
   if (!k) return;
   printf("Note: %s Line %d: %s %s\n",
           file_label[depth]->l.name,
           ll[depth],
           n,
           k);
}

#if 0
static void notep(char *n, char *k)
{
   if (!pass) return;
   if (!k) return;
   printf("Note: %s Line %d: %s %s\n",
           file_label[depth]->l.name,
           ll[depth],
           n,
           k);
}
#endif

static void note(char *k)
{
   if (!pass) return;
   if (!k) return;
   printf("Note: %s Line %d: %s\n", 
	   file_label[depth]->l.name,
	   ll[depth],
	   k);
}

static void note_either_pass(char *name, char *k)
{
   printf("Note: %s Line %d: %s %s\n",
           file_label[depth]->l.name,
           ll[depth],
           name,
           k);
}

#ifdef RELOCATION
#define RCHECK(x) if (mapx->m.l.y) rflag(x);
static void rflag(char *o)
{
   if (pass)
   {
      print_macrotext(64, o, "sub");
      putchar(10);
   }
   flag("arithmetic with relocatable address");
}
#endif
