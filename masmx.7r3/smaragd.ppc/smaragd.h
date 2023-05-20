typedef struct { void		*next;
		 int	     priority;
		 int		state;
		 void		*base; } tcb_header;

typedef struct { tcb_header	    h;
		 int	    save_srr0,
			    save_srr1,
			      save_cr,
			     save_xer,
			     save_ctr,
			      save_lr,
                    save_register[32]; } task_control_block;
