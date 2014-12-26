static object *isanequf(char *field)
{
   static label		 x;
   
   object		*l;
   
   long			 v;
   
   location_counter	*c;

   if (!field) return NULL;

   #ifdef AUTOMATIC_LITERALS
   if ((*field == '(') && (selector['a'-'a']))
   {
      c = &locator[litloc];
      
      if (c->flags & 128)
      {
         if (v = c->rbase)
         {
            quadinsert1(v, &x.value);
            #ifdef RELOCATION
            mapx->m.i = 0; /* global change 3ix2008 */
            #endif

            return (object *) &x;
         }
      }

      return NULL;
   }
   #endif
   
   l  = findlabel(field, NULL);
   if (!l) return NULL;

   #ifdef LITERALS
   if (l->l.valued == LTAG)
   {
      c = &locator[l->l.r.l.rel & 127];
      
      if (c->flags & 128)
      {
         v = quadextract1(&l->l.value);
         if (v != c->rbase) flag("not in scope of this literal tag");

         #ifdef RELOCATION
         mapx->m.i = 0; /* global change 3ix2008 */
         #endif

         return l;
      }
   }
   #endif

   if (l->l.valued ==  EQUF) return l;

   if (l->l.valued == BLANK)
   {
      c = &locator[l->l.r.l.rel & 127];
      if (c->flags & 128) return l;
   }

   return NULL;
}
