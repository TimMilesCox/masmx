static object *insert_qltable(char *l, long equator, int type)
{
   line_item		 local = zero_o;

   #ifdef XTENDA
   if ((type == LOCATION) && (selector['i'-'a'] == 0))
   {
   }
   else
   {
      if (equator < 0)	 local = minus_o;
   }
   #else
   if ((type ^ LOCATION) && (equator < 0)) local = minus_o;
   #endif

   quadinsert(equator, &local);

   return insert_ltable(l, NULL, &local, type);
}
