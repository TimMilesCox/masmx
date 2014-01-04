static void quadd_u(unsigned long j, line_item *i)
{
   line_item		 from = zero_o;

   if ((selector['i'-'a']) && (j & 0x80000000)) from = minus_o;

   quadinsert(j, &from);
   operand_add(i, &from);
}
