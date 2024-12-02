
{REDUND_ERROR} FUNCTION_BLOCK legoSTRItemString (*Outputs an item string*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		trigger : BOOL; (*Trigger *)
		value : USINT; (*Value. [0-9], 20 = BACKSPACE 30 = CLEAR*)
	END_VAR
	VAR_OUTPUT
		item : STRING[MAX_ITEM_SIZE]; (*Item number*)
		internal : legoSTRItem_internal; (*Internal variables*)
	END_VAR
END_FUNCTION_BLOCK
