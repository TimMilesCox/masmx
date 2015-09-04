
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




static void internal_labels()
{
   static qui_tuple initial[] = {
    { "$directive", DIRECTIVE, EQU } , 
    { "$function", INTERNAL_FUNCTION, EQU } ,  

   #ifdef BINARY
   #ifdef RANGE_FLAGS
    { "$range_check",  RANGE_FLAGS,  EQU } ,
    { "$range_check1", RANGE_FLAGS1, EQU } ,
   #endif

    { "$offset", OFFSET, EQU } ,
    { "$binary", BINARY, EQU } ,
    { "$void", VOID, EQU } ,
   #endif

   #ifdef LONG_ABSOLUTE
    { "$long_absolute", LONG_ABSOLUTE, EQU } ,
   #endif

    { "$form", FORM, DIRECTIVE } , 
    { "$proc", PROC, DIRECTIVE } , 
    { "$name", NAME, DIRECTIVE } ,
    { "$end", END, DIRECTIVE } ,

    { "$do", DO, DIRECTIVE } ,   
   
    { "$if", IF, DIRECTIVE } ,   
    { "$else", ELSE, DIRECTIVE } ,

    { "$elseif", ELSEIF, DIRECTIVE } ,            
    { "$endif", ENDIF, DIRECTIVE } ,
   
    { "$include", INCLUDE, DIRECTIVE } ,
    { "$func", FUNCTION, DIRECTIVE } ,
   
   #ifdef EXIT
    { "$exit", EXIT, DIRECTIVE } ,
   #endif
   
    { "$equ", EQU, DIRECTIVE } ,
    { "$set", SET, DIRECTIVE } ,

    { "$data_code", DATA_CODE, DIRECTIVE } ,
    { "$ascii", ASCII, DIRECTIVE } ,
   
    { "$word", WORD, DIRECTIVE } ,
    { "$byte", BYTE, DIRECTIVE } ,
    { "$return", RETURN, DIRECTIVE } ,

    { "$list", LIST, DIRECTIVE } ,
   
   #ifdef PATH
    { "$path", PATH, DIRECTIVE } ,
   #endif

    { "$plist", PLIST, DIRECTIVE } ,
   
    { "$res", RES, DIRECTIVE } ,

   
   #ifdef LITS
    { "$lit", LITS, DIRECTIVE } ,
   #endif

    { "$snap", SNAP, DIRECTIVE } ,
    { "$quantum", QUANTUM, DIRECTIVE } ,
    { "$linewidth", LWIDTH, DIRECTIVE } ,
    { "$awidth", AWIDTH, DIRECTIVE } ,
    { "$lterm", LTERM, DIRECTIVE } ,
    { "$sterm", STERM, DIRECTIVE } ,
   
    { "$cont_char", CONT_CHAR, DIRECTIVE } ,
   
    { "$flag", FLAG, DIRECTIVE } ,
   
    { "$quote", QUOTEC, DIRECTIVE } ,
    
    { "$trace", TRACE, DIRECTIVE } ,
    { "$note", NOTE, DIRECTIVE } ,
    { "$text", TEXT_SUBSTITUTE, DIRECTIVE } ,

   #ifdef NOP
    { "$nop", NOP, DIRECTIVE } ,
   #endif

    { "$suffix", SUFFIX, DIRECTIVE } ,

   #ifdef EQUF
    { "$equf", EQUF, DIRECTIVE } ,
   #endif

    { "$octal", OCTAL, DIRECTIVE } ,
    { "$hex", HEX, DIRECTIVE } ,

   #ifdef BINARY
    { "$info", INFO, DIRECTIVE } ,
   #endif

    { "$set_option", SET_OPTION, DIRECTIVE } ,

   #ifdef STRUCTURE_DEPTH
    { "$tree", TREE, DIRECTIVE } ,
    { "$root", ROOT, DIRECTIVE } ,
    { "$branch", BRANCH, DIRECTIVE } ,
   #endif


    { "$flagf", FLAGF, DIRECTIVE } ,
    { "$notef", NOTEF, DIRECTIVE } ,
   
   #ifdef FLOATING_POINT
    { "$floating_point", FLOATING_POINT, DIRECTIVE } ,
    { "$characteristic", CHARACTERISTIC, DIRECTIVE } ,
   #endif
   
   #ifdef TWOSCOMP
    { "$twos_complement", TWOSCOMP, DIRECTIVE } ,
   #endif

   #ifdef BINARY
    { "$pushrel", PUSHREL, DIRECTIVE } ,
   #endif

   #ifdef BINARY
    { "$load", LOAD, DIRECTIVE } ,
   #endif

   #ifdef BLANK
    { "$blank", BLANK, DIRECTIVE } ,
   #endif

    { "$store", STORE, DIRECTIVE } ,

    { "$", LOCTR, INTERNAL_FUNCTION } ,
    { "$n", PNAME, INTERNAL_FUNCTION } ,
   

    { "$r", REGION, INTERNAL_FUNCTION } ,
    { "$t", TYPE, INTERNAL_FUNCTION } ,
    { "$o", OPTION, INTERNAL_FUNCTION } ,
    { "$rel", REL, INTERNAL_FUNCTION } ,   
    { "$net", NET, INTERNAL_FUNCTION } ,

   #ifdef ABSOLUTE
    { "$a", ABSOLUTE, INTERNAL_FUNCTION } ,
   #endif

   #ifdef SIMPLE_BASE
    { "$b", SIMPLE_BASE, INTERNAL_FUNCTION } ,
   #endif

   #ifdef BANK_INDEX
    { "$bank_index", BANK_INDEX, INTERNAL_FUNCTION } ,
   #endif

   #ifdef SYM
    { "$sym", SYM, DIRECTIVE } ,
   #endif

   #ifdef FP_XPRESS
    { "$xqt_fp", FP_XPRESS, DIRECTIVE } ,
   #endif

   #ifdef ESPRESSO
    { "$xqt_i", ESPRESSO, DIRECTIVE } ,
   #endif

   #ifdef RECORD
    { "$record", RECORD, DIRECTIVE } ,
   #endif

   #ifdef ZENITH
    { "$zenith", ZENITH, INTERNAL_FUNCTION } ,
   #endif

   #ifdef ZERO_CODE_POINT
    { "$zero_code_point", ZERO_CODE_POINT, DIRECTIVE } ,
   #endif

    { NULL, 0, 0 } } ;

   qui_tuple		*q = initial;
   object		*sr;

   while (q->name)
   {
      sr = insert_qltable(q->name, q->value, q->type);
      if (q->type  ==      EQU) sr->l.valued = EQU;
      q++;
   }
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


