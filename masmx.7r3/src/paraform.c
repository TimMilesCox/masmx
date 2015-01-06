static int fields(char *g)
{
   int i = 0, j;   
   atree *a = vtree[masm_level-1];
   array *b = a->field;

   if (a->ready) return a->count;

   #ifdef WALKV
   if ((selector['p'-'a'] | selector['q'-'a']) && (plist > masm_level))
   printf("PSetup :%s\n", g);
   #endif

   a->ready = 1;
   a->count = i;

   a->field[0].image[0] = NULL;
   a->field[0].count = 0;

   g = getop(g);

   #ifdef WALKV
   if ((selector['p'-'a'] | selector['q'-'a']) && (plist > masm_level))
   printf("OSetup :%s\n", g);   
   #endif

   if (!g)
   {
      vtree[masm_level] = (atree *) b;
      return 0;
   }
   
   for (;;)
   {
      j = 1;
      b->image[0] = g;
      g = first_at(g, ", ");

      while (*g == ',')
      {
	 g++;
	 while(*g == 32) g++;
         if (*g == 0) break;
         b->image[j] = g;

         #ifdef WALKV
         if ((selector['p'-'a'] | selector['q'-'a']) && (plist > masm_level))
         printf("%d:%s\n", j, g);
         #endif

	 g = first_at(g, ", ");
         j++;
      }

      b->count = j;
      b = (array *) &b->image[j];

      while (*g == 32) g++;
      if (*g == 0) break;
      i++;
   }

   a->ready = 1;
   a->count = i;

   vtree[masm_level] = (atree *) b;
   b->ready = 0;
   b->count = 0;

   return i;
}

static array *field(int i)
{
   atree *b = vtree[masm_level-1];
   array *a = b->field;

   if (i > b->count) return NULL;

   while (i--) a = (array *) &a->image[a->count];
   return a;
}

static int substrings(char *g)
{
   int i = 0;
   if (!g) return 0;
   for (;;)
   {
      i++;
      g = first_at(g, tstring);
      if (*g++ != sterm) return i;
   }
}

static char *substring(char *g, int i)
{
   if (!g) return NULL;

   for (;;)
   {
      i--;
      if (!i) break;
      g = first_at(g, tstring);
      if (*g++ != sterm) return NULL;
   }
   return g;
}


/********************************************

	this is a comment and reminder
	of definitions in data.c

#define BAD_PARAFORM	0
#define COMPLETE_LINE	1
#define ALL_FIELDS	2
#define	FIELD		3
#define SUBFIELD	4
#define STAR_SUBFIELD	4+128
#define HASH_SUBFIELD	4+64
#define	SUBSTRING	5
#define STAR_OR_HASH_	128+64
#define STAR__		128
#define HASH__		64

typedef struct { char level,field,subfield,sustring; } paraform_code;

********************************************/


static paraform_code encode_paraform(char *p, char **s)
{
   paraform_code	 z = { COMPLETE_LINE, 0, 0, 0 } ;

   int			 symbol;
   char			*q;


   if (!p) return z;

   if (symbol = *p)
   {
      #ifdef SLIPSHO
      printf("[%c][%s]", symbol, p);
      #endif
      p++;
      if (symbol == '(')
      {
         if (*p == ')')
         {
            p++;
            z.level = ALL_FIELDS;
         }
         else
         {
            q = edge(p, ",)");
            z.field = expression(p, q, NULL);
            p = q;
            z.level = FIELD;

            if (symbol = *p)
            {
               p++;
               if (symbol == ',')
               {
                  q = edge(p, ":)");
                  while(*p == 32) p++;
                  z.level = SUBFIELD;

                  if (*p == '*')
                  {
                     z.level = STAR_SUBFIELD;
                     p++;
                  }

                  if (*p == '#')
                  {
                     z.level = HASH_SUBFIELD;
                     p++;
                  }

                  z.subfield = expression(p, q, NULL);
                  p = q;

                  if (symbol = *p)
                  {
                     p++;
                     if (symbol == ')')
                     {
                     }
                     else
                     {
                        if (symbol == ':')
                        {
                           q = edge(p, ")");
                           while (*p == 32) p++;

                           z.sustring = expression(p, q, NULL);
                           z.level = SUBSTRING;
                           p = q;

                           if (symbol = *p)
                           {
                              p++;
                           }
                        }
                        else
                        {
                           z.level = BAD_PARAFORM;
                        }
                     }
                  }
               }
            }
         }
      }
   }

   #ifdef SLIPSHO
   printf("[encode %d %8.8x]", z.level, z);
   #endif

   if (s) *s = p;
   return z;
}

static char *text_image(paraform_code sample, char *gparam)
{
   #ifdef PART_EQUF
   static char	dynamic_name[248];
   #else
   static char 	dynamic_name[248] = "$subfield\\";
   #endif

   int			 x = sample.field,
                         y;

   object		*o, *p, *q;

   char			*pq;

   #ifdef INTEL
   unsigned char	*quartet;
   #endif

   long			 v;

   array		*a;

   
   if (!gparam) return "";

   y = fields(gparam);
   if (x > y) return "";
   a = field(x);

   switch (sample.level)
   {
      case SUBFIELD:
      case STAR_SUBFIELD:
      case HASH_SUBFIELD:

         y = sample.subfield;
         if (y < 0) return "";
         if (!y) y = 1;

         if ((y > a->count) || (*a->image[y - 1] == ','))
         {
            x = a->count;
            if (x > y) x = y;

            while (x--)
            {
               #ifdef PART_EQUF

               pq = a->image[x];

               if ((*pq == '*') || (*pq == '#')) pq++;

               if (o = isanequf(pq))
               {
                  #ifdef INTEL

                  quartet = &o->l.value.b[RADIX/8-((y - x) << 2)];

                  v = (quartet[0] << 24)
                  |   (quartet[1] << 16)
                  |   (quartet[2] <<  8)
                  |    quartet[3];

                  #else

                  v = o->l.value.i[RADIX/32-(y - x)];

                  #endif

                  if ((address_size < 32) && (v & 0x80000000))
                  {
                       sprintf(dynamic_name, "*%ld", v & 0x7FFFFFFF);
                  }
                  else sprintf(dynamic_name, "%ld", v);

                  return dynamic_name;
               }

               #else

               if (o = isanequf(a->image[x]))
	       {
                  if (p = findlabel("$subfield", NULL))
                  {
                     if ((p->l.valued == FUNCTION)
                     ||     ((p->l.valued == NAME)
                         &&  (q = p->l.along)
                         &&  (q->l.valued == FUNCTION)))
                     {
                        sprintf(&dynamic_name[10], "%s(%d)",
                                o->l.name, y - x);
                        return dynamic_name;
                     }
                  }

                  flag("user supplied $SUBFIELD macro required");
                  return "";
               }

               #endif

            }
            return "";
         }

         gparam = a->image[y-1];
         if (!gparam) return "";

         return gparam;

      case SUBSTRING:

         y = sample.subfield;
         if (y < 0) return "";
         if (!y) y = 1;
         if (y > a->count) return "";
         gparam = a->image[y-1];
         if (!gparam) return "";

         x = sample.sustring;
   
         gparam = substring(gparam, x);
         if (!gparam) return "";
   
         return gparam;

      case FIELD:

         return a->image[0];

      case ALL_FIELDS:

      case COMPLETE_LINE:
         return gparam;
   }

   return gparam;
}

static char *substitute(char *search, char *param)
{
   static char		 subterfuge[4096];
   static char		*sublime[72] = { subterfuge } ;
   
   char			*v; 
   char			*vv;
   int			 inquote, symbol;
   int			 inbe, btype;

   paraform_code	 sample;

   if (!search)
   {
      flag_either_pass("Internal Error 6", "abandon");
      exit(0);
   }

   if (!masm_level) return search;

   v = sublime[masm_level - 1];
   sublime[masm_level] = v;

   if (!param) return search;

   fields(param);

   #ifdef WALKP
   printf("-PARAMSUB-%s/%s\n", search, param);
   #endif
   
   if (!v)
   {
      flag_either_pass(search, "internal error 5");
      exit(0);
   }
   
   if (v > &subterfuge[4032])
   {
      flag_either_pass("Excessive Parameter Substitution", "abandon");
      exit(0);
   }
   
   while (symbol = *search++)
   {
      if (symbol == ESC)
      {
         sample = encode_paraform(search, &search);
         vv = text_image(sample, param);
         inquote = 0;
               
         switch (sample.level & 63)
         {

            case SUBFIELD:
 
               #ifdef PARAFORM_TRACE
               if (plist > masm_level)
               {
                  if (((pass) && (selector['p'-'a'] | selector['q'-'a']))
                  || ((!pass) && (selector['r'-'a'])))
                  {
                     printf("subfield %d,%d [%s]\n", sample.field,
                                                sample.subfield, vv);
                  }
               }
               #endif

               inbe = 0;

	       while (symbol = *vv++)
	       {
	          if (symbol == qchar)
                  {
                     if ((inquote & 2) == 0) inquote ^= 1;
                  }
                  else
                  {
                     if (symbol == 0x27)
                     {
                        if ((inquote & 1) == 0) inquote ^= 2;
                     }
                  }

                  if (!inquote)
                  {
                     if (symbol == '(') inbe++;
                     if (symbol == ')') inbe--;
                  }

	          if ((inquote | inbe) == 0)
	          {
	             if (symbol == ' ') break;
		     if (symbol == ',') break;
	          }
   
	          *v++ = symbol;
	       }
               break;

            case SUBSTRING:

               #ifdef PARAFORM_TRACE
               if (plist > masm_level)
               {
                  if (((pass) && (selector['p'-'a'] | selector['q'-'a']))
                  || ((!pass) && (selector['r'-'a'])))
                  {
                     printf("substring %d,%d:%d\n", sample.field,
                                                    sample.subfield,
                                                    sample.sustring);
                  }
               }
               #endif

               inbe = 0;
               btype = 0;

	       while (symbol = *vv++)
	       {
                  if (!inquote)
                  {
                     if (btype == '[')
                     {
                        if (symbol == ']') btype = 0;
                     }
                     else
                     {
                        if (symbol == '(') inbe++;
                        if (symbol == ')') inbe--;
                     }
                     if (!inbe)
                     {
                        if (symbol == '[') btype = '[';
                     }
                  }

	          if (symbol == qchar)
                  {
                     if ((inquote & 2) == 0) inquote ^= 1;
                  }
                  else
                  {
                     if (symbol == 0x27)
                     {
                        if ((inquote & 1) == 0) inquote ^= 2;
                     }
                  }

		  if ((inquote | inbe | btype) == 0)
	          {
		     if (symbol ==   ' ') break;
		     if (symbol ==   ',') break;
		     if (symbol == sterm) break;
		  }

		  *v++ = symbol;
	       }

               break;

            case FIELD:

               #ifdef PARAFORM_TRACE
               if (plist > masm_level)
               {
                  if (((pass) && (selector['p'-'a'] | selector['q'-'a']))
                  || ((!pass) && (selector['r'-'a'])))
                  {
                     printf("field %d\n", sample.field);
                  }
               }
               #endif

               inbe = 0;

	       for (;;)
	       {
	  	  while (symbol = *vv++)
		  {
                     if (!inquote)
                     {
                        if (symbol == '(') inbe++;
                        if (symbol == ')') inbe--;
                     }

		     if (symbol == qchar)
                     {
                        if ((inquote & 2) == 0) inquote ^= 1;
                     }
                     else
                     {
                        if (symbol == 0x27)
                        {
                           if ((inquote & 1) == 0) inquote ^= 2;
                        }
                     }

	             if ((inquote | inbe) == 0)
		     {
			if (symbol == ' ') break;
			if (symbol == ',') break;
	             }

		     *v++ = symbol;
		  }

		  if (symbol != ',') break;
		  *v++ = symbol;

                  while (symbol = *vv)
                  {
                     if (symbol != 32) break;
                     vv++;
                  }
			
	       }

               break;

            case ALL_FIELDS:

               #ifdef PARAFORM_TRACE
               if (plist > masm_level)
               {
                  if (((pass) && (selector['p'-'a'] | selector['q'-'a']))
                  || ((!pass) && (selector['r'-'a'])))
                  {
                     printf("all fields\n");
                  }
               }
               #endif

               while (symbol = *vv++) *v++ = symbol;

               break;

            case COMPLETE_LINE:

               #ifdef PARAFORM_TRACE
               if (plist > masm_level)
               {
                  if (((pass) && (selector['p'-'a'] | selector['q'-'a']))
                  || ((!pass) && (selector['r'-'a'])))
                  {
                     printf("line image\n");
                  }
               }
               #endif

               while (symbol = *vv++) *v++ = symbol;

               break;

            case BAD_PARAFORM:
               flag("paraform not decoded");
         }
      }
      else *v++ = symbol;
   }
   *v++ = 0;
   sublime[masm_level] = v;
   return sublime[masm_level - 1];
}


