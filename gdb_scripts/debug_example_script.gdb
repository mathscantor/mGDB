set confirm off
set pag off
set print pretty on
set output-radix 16
set disassembly-flavor intel
set print elements 0
set cwd .

source gdb_scripts/py_commands/strlen.py
source gdb_scripts/py_commands/get_base_addr.py
source gdb_scripts/py_commands/load_library_symbol.py
source gdb_scripts/py_commands/step_into.py
source gdb_scripts/py_commands/json_get_value_from_key.py

load_library_symbol /usr/lib/x86_64-linux-gnu libc.so.6

get_base_addr test
printf "base addr: %p\n", $get_base_addr_ret

b func_1
commands
  silent
  step_into 3
  continue
end

b func_2
commands
  info registers rdi
  x/16bx $rdi
  strlen $rdi
  printf "len: %d\n", $strlen_ret
  continue
end

b func_3
commands
  info registers rdi
  x/16bx $rdi
  json_get_value_from_key $rdi user2.name
  continue
end

continue


