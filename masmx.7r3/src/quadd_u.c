static void quadd_u(unsigned long j, line_item *i)
{
   line_item		 from = zero_o;

   #ifdef XTENDA
   if ((selector['i'-'a']) && (j & 0x80000000)) from = minus_o;
   #endif

   quadinsert(j, &from);
   operand_add(i, &from);
}
