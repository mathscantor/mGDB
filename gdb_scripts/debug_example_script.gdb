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
source gdb_scripts/py_commands/json_get_value_from_key.py
source gdb_scripts/py_commands/peek_n_step_into.py

load_library_symbol /usr/lib/x86_64-linux-gnu libc.so.6

get_base_addr ./test_binaries/test
printf "base addr of test: %p\n", $get_base_addr_ret

b func_1
commands
  peek_n_step_into 3
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
  json_get_value_from_key $rdi "user1.name"
  json_get_value_from_key $rdi "user2"
  continue
end

continue


