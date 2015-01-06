
/*************************************************

	this is for adding address offsets
	to giant addresses

	it may not be used for signed addition

*************************************************/


static void quadd_u(unsigned long j, line_item *i)
{
   line_item		 from = zero_o;

   quadinsert(j, &from);
   operand_add(i, &from);
}
