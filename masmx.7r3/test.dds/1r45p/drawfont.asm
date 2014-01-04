;       ******************************************************************
;       *       File    DRAWFONT.ASM    Tim, xij99 ***********************
;       ******************************************************************
;       *       Macros which copy all or some of the bits in the         *
;       *       4*expanded font in the XFONT: table into the bitmap for  *
;       *       output. The anatomy of the expanded font table is that   *
;       *       each pixel in the basic character HFONT: table has an    *
;       *       equivalent 4*4=16 bits in XFONT: Thus each octet in HFONT*
;       *       equates for four lines of four octets in XFONT:          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *       The bit mask for the whole data character is represented *
;       *       by eight such constructs in a continuous table:          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *                                                                *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       *               bbbb BBBB bbbb BBBB bbbb BBBB bbbb BBBB          *
;       ******************************************************************
;       *                                                                *
;       *       The whole collating sequence is modelled by              *
;       *       128 * the above table.                                   *
;       *       Some of the patterns 0..31 appear to be useful glyphs for*
;       *       graphics and unusual character composition.              *
;       *                                                                *
;       *       The 128 patterns are included as                         *
;       *                                                                *
;       *             D:\DEV\XQ10\SLAVE\FONTS\actual.font\XFONT1.ASM     *  
;       *             D:\DEV\XQ10\SLAVE\FONTS\actual.font\XFONT2.ASM     *  
;       *             D:\DEV\XQ10\SLAVE\FONTS\actual.font\XFONT3.ASM     *  
;       *             D:\DEV\XQ10\SLAVE\FONTS\actual.font\XFONT4.ASM     *  
;       *                                                                *
;       *       The four files in directory[actual.font] are edited or   *
;       *       generated in a more clever way to
;       *       produce the fine variation desired on the versions found *
;       *       in                                                       *
;       *                                                                *
;       *             D:\DEV\XQ10\SLAVE\FONTS\BASIC\XFONT1.ASM           *
;       *             D:\DEV\XQ10\SLAVE\FONTS\BASIC\XFONT2.ASM           *
;       *             D:\DEV\XQ10\SLAVE\FONTS\BASIC\XFONT3.ASM           *
;       *             D:\DEV\XQ10\SLAVE\FONTS\BASIC\XFONT4.ASM           *
;       *                                                                *
;       *       There are four of these files because ECAL Assembly      *
;       *       package is restricted to source files of about 64Kbytes  *
;       *       of text. The source symbols are encoded as explicit      *
;       *       binary, e.g.                                             *
;       *                                                                *
;       *               DB      00001111b, 11111111b, 11110000b, 00000000b
;       *                                                                *
;       *       All four files generate 16384 bytes of compiled code in  *
;       *       instruction memory. If further symbols are desired it is *
;       *       possible to generate and include XFONT5, XFONT6, XFONT7  *
;       *       and XFONT8 files containing graphics elements,           *
;       *       alternative alphabets or whatever (and of course it is   *
;       *       possible to replace the Roman alphabet in XFONT3,XFONT4).*
;       ******************************************************************
;       *                                                                *
;       *       For The AXIOHM Printer, only 6 bits are used in each byte*
;       *       of the Print Bit Map                                    *
;       *       These files contain a 4*magnification. Of course         *
;       *                                                                *
;       *       For 2*horizontal magnification, 1/2 bits in each row of  *
;       *       of the character font bitmap must be orred               *
;       *       into the print bit map.                                  *
;       *                                                                *
;       *       For 2*vertical magnification, 1/2 rows of the character  *
;       *       font bitmap should be processed.                         *
;       *                                                                *
;       *       For 3*horizontal magnification, 3/4 bits in each row of  *
;       *       of the character font bitmap must be orred               *
;       *       into the print bit map.                                  *
;       *                                                                *
;       *       For 3*vertical magnification, 3/4 rows of the character  *
;       *       font bitmap should be processed.                         *
;       *                                                                *
;       *       For 4*horizontal magnification, all bits in each row of  *
;       *       of the character font bitmap must be orred               *
;       *       into the print bit map.                                  *
;       *                                                                *
;       *       For 4*vertical magnification, all rows of the character  *
;       *       font bitmap should be processed.                         *
;       *                                                                *
;       *       For 5*horizontal magnification, all bits in each row of  *
;       *       of the character font bitmap must be orred               *
;       *       into the print bit map with every fourth bit propagated  *
;       *       twice.                                                   *
;       *                                                                *
;       *       For 5*vertical magnification, all rows of the character  *
;       *       font bitmap should be processed, with every fourth row   *
;       *       processed onto two rows of the print bit map.            *
;       *                                                                *
;       *       For 6*horizontal magnification, all bits in each row of  *
;       *       of the character font bitmap must be orred               *
;       *       into the print bit map with every second bit propagated  *
;       *       twice.                                                   *
;       *                                                                *
;       *       For 6*vertical magnification, all rows of the character  *
;       *       font bitmap should be processed, with every second row   *
;       *       processed onto two rows of the print bit map.            *
;       *                                                                *
;       *       For 7*horizontal magnification, all bits in each row of  *
;       *       of the character font bitmap must be orred               *
;       *       into the print bit map with 3/4 bits propagated twice.   *
;       *                                                                *
;       *       For 7*vertical magnification, all rows of the character  *
;       *       font bitmap should be processed, with every 3/4 rows     *
;       *       processed onto two rows of the print bit map.            *
;       *                                                                *
;       *       For 8*horizontal magnification, all bits in each row of  *
;       *       of the character font bitmap must be propagated twice    *
;       *       and orred into the print bit map.                        *
;       *                                                                *
;       *       For 8*vertical magnification, all rows of the character  *
;       *       font bitmap should be processed onto two rows of the     *
;       *       print bit map.                                           *
;       *                                                                *
;       ******************************************************************
;       *                                                                *
;       *       Any magnification not implemented should fold to the next*
;       *       lower. The whole purpose of this exercise is that        *
;       *       magnifications *2, *3, *4 should not look rough. The     *
;       *       refinement consists in tuning the XFONTx.ASM files to    *
;       *       remove crow-stepped diagonals and curves, but anyone     *
;       *       who wants to output XFONTx.ASM files from a smart        *
;       *       GUI-based program can do anything they like with fonts.  *
;       ******************************************************************

XFONTP  EQU     1

        END
