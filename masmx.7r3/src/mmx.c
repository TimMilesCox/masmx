
/******************************************************************

                Copyright Tim Cox, 2015

                TimMilesCox@gmx.ch

        This source code is a utility used in conjunction
	with the masmx.7r3 target-independent meta-assembler

        The masmx.7r3 meta-assembler is free software licensed
        with the GNU General Public Licence Version 3

        The same licence encompasses all accompanying software
        and documentation

        The full licence text is included with these materials

        See also the licensing notice at the foot of this document

*******************************************************************/





#ifdef DOS
#include <stdio.h>
#include <io.h>
#include <dos.h>
#include <fcntl.h>
#include <sys\stat.h>
#else
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

static char include[72] = { 1,1,1,1,1,1,1,1,1,1,1,1, 
                            1,1,1,1,1,1,1,1,1,1,1,1,
                            1,1,1,1,1,1,1,1,1,1,1,1,
                            1,1,1,1,1,1,1,1,1,1,1,1,
                            1,1,1,1,1,1,1,1,1,1,1,1,
                            1,1,1,1,1,1,1,1,1,1,1,1 } ;

void exout(int locator, int loc, char *b, int c, int handle, int flag)
{
   static int loc0 = 0;
   static char data[80];
   static char plen[4];
   static int index=12, sum=0, p=0, first = 73;
   register char digit;

   if (!include[locator]) return;
   if ((loc) || (first != locator) || (flag == 7))
   {
      first = locator;
      if (p)
      {
         sum += p;
         sum += 5;
         sum ^= -1;
         data[0] = 'S';
         data[1] = '3';
         sprintf(plen, "%2.2X", p+5);
         data[2] = plen[0];
         data[3] = plen[1];
         index += sprintf(&data[index], "%2.2X\n", sum & 255);
         write(handle, data, index);
      }
      sum = (loc>>24)+(loc>>16)+(loc>>8)+loc;
      
      p = 0;
      loc0 = loc;
      index = 12;

      if (flag == 7)
      {
         sprintf(data, "S705%8.8X", loc0);
         sum += 5;
         sum ^= -1;
         sum &= 255;
         index = 12+sprintf(&data[12], "%2.2X\n", sum);
         write(handle, data, index);
         return;
      }
      
      sprintf(data, "S300%8.8X", loc0);
   }
   
   while (c)
   {
      sum += *b;
      index += sprintf(&data[index], "%2.2X", *b++);
      p++;
      c--;
      if (p > 19) 
      {
         sum += p;
         sum += 5;
         sum ^= -1;
         data[0] = 'S';
         data[1] = '3';
         sprintf(plen, "%2.2X", p+5);
         data[2] = plen[0];
         data[3] = plen[1];
         index += sprintf(&data[index], "%2.2X\n", sum & 255);
         write(handle, data, index);
         loc0 += p;
         sum = (loc0>>24)+(loc0>>16)+(loc0>>8)+loc0;
         sprintf(data, "S300%8.8X", loc0);
         index = 12;
         p = 0;
      }
   }
   
   if  ((flag == 1) && (p))
   {
      sum += p;
      sum += 5;
      sum ^= -1;
      data[0] = 'S';
      data[1] = '3';
      sprintf(plen, "%2.2X", p+5);
      data[2] = plen[0];
      data[3] = plen[1];
      index += sprintf(&data[index], "%2.2X\n", sum & 255);
      write(handle, data, index);
      loc0 += p;
      sum = (loc0>>24)+(loc0>>16)+(loc0>>8)+loc0;
      sprintf(data, "S300%8.8X", loc0);
      index = 12;
      p = 0;
   }
}

int main(int argc, char *argv[])
{
  #ifdef DOS
  int i = open(argv[1], O_RDONLY|O_TEXT);
  int j = open(argv[2], O_WRONLY|O_CREAT|O_TRUNC|O_TEXT, S_IREAD|S_IWRITE);
  #else
  int i = open(argv[1], O_RDONLY);
  int j = open(argv[2], O_WRONLY | O_CREAT |O_TRUNC,
                        S_IREAD  | S_IWRITE|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
  #endif
  
  int c, d, locator, e, f, symbol, x, interval, y = 0;
  int loc, transfer, offset = 0;
  char data[256];
  char internal[128];
  char *p;
  
  register char digit1, digit2;
  
  if (i < 1)
  {
     printf("input file %s unavailable\n", argv[1]);
     return i;
  }

  if (j < 1) 
  {
     printf("output file %s not written\n", argv[2]);
     return j;
  }

  write(j, "S00600004844521B\n", 17);
  
  for (;;)
  {
    c = 0;
    for (;;)
    {
      d = read(i, &data[c], 1);
      if (!d) break;
      if (data[c] == 0x0d) continue;
      if (data[c] == 0x0a) break;
      c++;
    }
    /*
    if (!d) break;
    */
    if (!c)
    {
      if (!d) break;
      continue;
    }
    if (data[0] == ':') continue;
    if (data[0] == '+') continue;
    if (data[0] == '.') continue;
    if (data[0] == '@') continue;
    if (data[0] == '-')
    {
       p = data;
       while ((symbol = *p++))
       {
          if (symbol == 0x0D) continue;
          if (symbol == 0x0A) break;
          putchar(symbol);
       }
       printf(" unresolved\n");
       continue;
    }
    
    data[c] = 0;
    if (data[0] == '$')
    {
       if (data[4] == '*')
       {
          printf("Relocatable Counter Not Used\n");
          continue;
       }
       offset = 0;
       x = sscanf(&data[1], "%x:%x", &locator, &loc);
       if (x < 2)
       {
          printf("bad location line\n");
          continue;
       }
       exout(locator, loc, NULL, 0, j, 0); 
       continue;
    }
    if (data[0] == '>')
    {
       sscanf(&data[1], "%x:%x", &locator, &transfer);
       if (x < 2)
       {
          printf("bad transfer line\n");
          continue;
       }
       y = 1;
       continue;
    }
    e = 0;
    interval = 0;
    p = data;
    while ((digit1 = *p++))
    {
       if (digit1 == ':')
       {
          printf("$%2.2x:%8.8x relocation information discarded %s\n",
                               locator, loc + offset + interval, data);
          e = interval;
          continue;
       }

       if (digit1 == 32)
       {
          interval = e;
          continue;
       }

       digit1 -= 48;
       if (digit1>9)
       {
          digit1 &= 15;
          digit1 += 9;
       }
       digit1 <<= 4;
       digit2 = *p++;
       if (!digit2) break;
       digit2 -= 48;
       if (digit2>9)
       {
          digit2 &= 15;
          digit2 += 9;
       }
       digit1 |= digit2;
       internal[e++] = digit1;
    }
    offset += e;
    exout(locator, 0, internal, e, j, 0);
    if (!d) break;
  }

  if (y) exout(locator, transfer, internal, e, j, 7);

  /* exout(0, 0, internal, c, j, 0); */
  exout(0, 0, NULL, 0, j, 1);
  close(i);
  close(j);
  return 0;
}

/**************************************************************************


LICENCE NOTE

    Copyright Tim Cox, 2015
    TimMilesCox@gmx.ch

    This source code is a utility used in conjunction with
    the masmx.7r3 target-independent meta-assembler. For the
    purposes of licensing it is part of masmx.7r3

    masmx.7r3 is free software. It is licensed
    under the GNU General Public Licence Version 3

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


