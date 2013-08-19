/***************************************************************

    Copyright   Tim Cox, 2012
    TimMilesCox@gmx.ch
    
    This file is part of masmx.7r2

    mamsx.7r2 is a target-independent meta-assembler for all
    architectures

    masmx.7r2 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    mamsx.7r2 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with masmx.7r2.  If not, see <http://www.gnu.org/licenses/>.


***************************************************************/


static object *buy_ltable()
{
   object *sr;
   lr->h.type = BYPASS_RECORD;
   lr->h.length = remainder+MARGIN;
   lr->nextbdi.next = 0;
   banx++;

   if (banx == BANKS)
   {
      printf("[%d] too many long labels\n", banx);
      exit(-1);
   }   
   
   #if 0
   if (selector['Z'-65]) printf("#%d.\n", banx);
   #endif
   
   sr = (object *) malloc(BANK);
   
   if (!sr) 
   {
      printf("[%d] Too Many Long Labels\n", banx);
      exit(-1);
   }   
   
   lr->nextbdi.next = banx;
   bank[banx] = sr;
   lr = sr;
   remainder = BANK-MARGIN;
   return sr;
}
