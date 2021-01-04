        
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



#define	ASIDE_BUFFER	4096

static char *stack_string(char *q)
{
   static char		 aside[ASIDE_BUFFER];
   static char		*p = aside;

   char			*from = q;
   char			*to = p;


   if (to > (aside + ASIDE_BUFFER - 120)) p = to = aside;

   while ((*to++ = *from++))
   {
      if (to > (aside + ASIDE_BUFFER - 4))
      {
         p = to = aside;
         from = q;
      }
   }

   from = p;
   p = to;
   return from;
}

static char *substitute_alternative(char *s, char *param)
{
   if (selector['q'-'a']) printf("[%x:a::%p \"%s\"]\n", masm_level, s, s);

   if ((masm_level) && (s))
   {
      s = substitute(s, param);

      if (s) s = stack_string(s);
   }

   if (selector['q'-'a']) printf("[%X:A::%p \"%s\"]\n", masm_level, s, s);
   return s;
}

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


