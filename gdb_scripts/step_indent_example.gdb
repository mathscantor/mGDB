set confirm off
set pag off
set print pretty on
set output-radix 16
set disassembly-flavor intel
set print elements 0
set logging enabled on

define peek_n_steps_into
	printf "<#__start__#>\n"
	set $num_steps = $arg0
	while ($num_steps > 0)
		si
		x/i $pc
		set $num_steps = $num_steps - 1
	end
	printf "<#__end__#>\n"
	continue
end

b func_1
commands 1
	peek_n_steps_into 500
end
continue
