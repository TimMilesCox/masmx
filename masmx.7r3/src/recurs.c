         #ifdef DEEP_RECURS
         if ((x == PROC) || (x == FUNCTION))
         {
            #if 0
            ndirect = substitute(line, argument);
            directive = getop(ndirect);
            #endif

            k = floatop;
            masm_level++;

            #ifdef TRACE_RECURS
            printf("[++%s:%d:%s]\n", ndirect, masm_level, param);
            #endif

            #ifdef FOLLOW_RECURS
            printf("++%s:%d\n", ndirect, masm_level);
            #endif

            embed_procedure(x, line, getop(op));

            pack_ltable(k);

            masm_level--;

            return 0;
         }
         #endif

