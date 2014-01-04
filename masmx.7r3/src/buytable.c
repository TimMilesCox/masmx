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
