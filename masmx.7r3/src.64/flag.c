
/******************************************************************

                Copyright Tim Cox, 2015

                TimMilesCox@gmx.ch

        This source code is part of the masmx.7r3
        target-independent meta-assembler

        The masmx.7r3 meta-assembler is free software licensed
        with the GNU General Public Licence Version 3

        The same licence encompasses all accompanying software
        and documentation

        The full licence text is included with these materials

        See also the licensing notice at the foot of this document

*******************************************************************/





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

static void flagz()
{
   if (!pass) return;

   ecount++;
   printf("Error: %s Line %d: ", file_label[0]->l.name, ll[0]);
}

static void notez()
{
   if (!pass) return;

   printf("Note: %s Line %d: ", file_label[0]->l.name, ll[0]);
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

static void flag_file_access()
{
   int x = depth;

   if (x) x--;
   printf("Error %d: %s Line %d: file missing: %s\n",
           errno,
           file_label[x]->l.name,
           ll[x],
           name);
}

#ifdef CLEATING
static void cleat(int context, object *p)
{
   printf("[%x:%2.2x:%2.2x]\n", context, p->h.type, *p->t.text);
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

   if (!selector['u'-'a']) return;

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

/**************************************************************************


LICENCE NOTE

    Copyright Tim Cox, 2015
    TimMilesCox@gmx.ch

    This source code is part of the masmx.7r3 target-independent
    meta-assembler.

    masmx.7r3 is free software. It is licensed
    under the GNU General Public Licence Version 3.

    You can redistribute it and/or modify masmx.7r3
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    masmx.7r3 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with masmx.7r3.  If not, see <http://www.gnu.org/licenses/>.

*************************************************************************/


