static object *insert_qltable(char *l, long equator, int type)
{
   line_item		 local = zero_o;

   if ((type ^ LOCATION) && (equator < 0)) local = minus_o;

   quadinsert(equator, &local);

   return insert_ltable(l, NULL, &local, type);
}
