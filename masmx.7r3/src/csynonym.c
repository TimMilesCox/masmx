
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




   #ifdef SYNONYMS
   static label count_synonyms = { LABEL, sizeof(label), 0, INTERNAL_FUNCTION,
				   { 0 },

                                     #ifdef HASH
                                     NULL,
                                     #endif

                                     #ifdef BINARY
                                     NULL,
                                     #endif

                                     NULL, NULL, 
				   { 0, 0, 0, 0, 0, 0,

                                     #if RADIX==192
				     0, 0, 0, 0, 0, 0,
				     0, 0, 0, 0, 0, 0,
                                     #endif

				     0, 0, 0, 0, 0, SYNONYMS }, "$$c" } ;
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


