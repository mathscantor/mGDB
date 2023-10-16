import sys
import re

#print(sys.argv)
if len(sys.argv)==1:
    print(f"Command: python3 {sys.argv[0]} <gdb_out>")
    exit()
input_file=sys.argv[1]
filename,sep,ext=input_file.partition('.')
output_file=filename+"_indent"+sep+ext
f_input=open(input_file,"r")
f_output=open(output_file,"w")

indent=6

record_packet_flag = False
while True:
    line = f_input.readline()
    if line == "":
        break
        
    if "=>" not in line:
        continue
        
    if "call" in line:
        f_output.write('  '*indent)
        f_output.write(line)
        indent+=1
  
    elif "ret" in line:
        f_output.write('  '*indent)
        f_output.write(line)
        indent-=1

f_input.close()
f_output.close()
