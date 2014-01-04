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
