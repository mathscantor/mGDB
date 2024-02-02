# mGDB (Multi-GDB)
**mGDB** is a user-friendly tool that manages the tedium of 
debugging multiple processes and its threads at the same time.

Table of Contents:
- [1. Usage](#1-usage)
  - [1.1 Starting a Session](#11-starting-a-session)
    - [1.1.1 Help (-h | --help)](#111-help--h----help)
    - [1.1.2 Process Name (-n | --process-name)](#112-process-name--n----process-name)
    - [1.1.3 A List of PIDs (-l | --pid-list)](#113-a-list-of-pids--l----pid-list-)
  - [1.2 Showing Sessions](#12-showing-sessions)
  - [1.3 Killing Sessions](#13-killing-sessions)
    - [1.3.1 Help (-h | --help)](#131-help--h----help)
    - [1.3.2 Killing a Particular Session (-t | --session-datetime)](#132-killing-a-particular-session--t----session-datetime)
    - [1.3.3 Killing all sessions managed by mGDB (-a | --all)](#133-killing-all-sessions-managed-by-mgdb--a----all)
    - [1.3.4 Killing All GDB Processes (-g | --global)](#134-killing-all-gdb-processes--g----global)
- [2. Extensions](#2-extensions)
- [3. Contributing](#3-contributing)

## 1. Usage
Please ensure that you are running all bash scripts as **root**.
### 1.1 Starting a Session
mGDB manages your gdb processes within a particular session. When you spawn
multiple gdb processes to hook onto your target processes, it will be managed
under a sessions categorized by the date and time that you run it.

To start a session, you can run `start_sessions.sh`

#### 1.1.1 Help (-h | --help)
<pre>
Usage: ./start_sessions.sh [ -h ] ( -n | -l ) -s [ -w ] [ -d ]
  -h | --help                   Show this help message and exit         
  -n | --process-name           The name of the process(es)             
  -l | --pid-list               A list of pids                          
  -s | --script                 Path to gdb script                      
  -w | --wait                   To wait on a process to spawn.          
                                This only works with (-n | --process-name)
  -d | --delay                  Delays the gdb attcachment in seconds. (integer/float)
</pre>

#### 1.1.2 Process Name (-n | --process-name)
In this example, I pre-ran 3 binaries called `test` and the
gdb script I am using is `gdb_scripts/debug_example_script.gdb`

<pre>
root@gerald-ubuntu:/home/gerald/repositories/mGDB# ./start_sessions.sh -n test -s gdb_scripts/debug_example_script.gdb 

<span style="color:#7FFF00">[INFO]</span> Debugging Session Mappings (16-10-2023T12-47-21)
-------------------- | -------------------- | --------------------
GDB PID              | PROCESS PID          | PROCESS NAME        
-------------------- | -------------------- | --------------------
9494                 | 9473                 | test                
9496                 | 9443                 | test                
9524                 | 9105                 | test                

All gdb output is redirected to:
 - /home/gerald/repositories/mGDB/logs/16-10-2023T12-47-21/gdb_output/9473_test.log
 - /home/gerald/repositories/mGDB/logs/16-10-2023T12-47-21/gdb_output/9443_test.log
 - /home/gerald/repositories/mGDB/logs/16-10-2023T12-47-21/gdb_output/9105_test.log

<span style="color:#7FFF00">[INFO]</span> Added mappings: /home/gerald/repositories/mGDB/logs/16-10-2023T12-47-21/mappings.txt
<span style="color:#7FFF00">[INFO]</span> Added database: /home/gerald/repositories/mGDB/database/16-10-2023T12-47-21/sessions.txt
<span style="color:#7FFF00">[INFO]</span> Added gdb script contents for reference: /home/gerald/repositories/mGDB/logs/16-10-2023T12-47-21/debug_example_script.gdb
</pre>

#### 1.1.3 A list of PIDs (-l | --pid-list )
Reusing the example in [1.1.2](#112-process-name---n----process-name-), instead of stating a process name, you can 
specify a list of PIDs to hook on. 
<pre>
root@gerald-ubuntu:/home/gerald/repositories/mGDB# ./start_sessions.sh -l 9473 9105 9443 -s gdb_scripts/debug_example_script.gdb 

<span style="color:#7FFF00">[INFO]</span> Debugging Session Mappings (16-10-2023T13-07-32)
-------------------- | -------------------- | --------------------
GDB PID              | PROCESS PID          | PROCESS NAME        
-------------------- | -------------------- | --------------------
10254                | 9473                 | test                
10256                | 9105                 | test                
10283                | 9443                 | test                

All gdb output is redirected to:
 - /home/gerald/repositories/mGDB/logs/16-10-2023T13-07-32/gdb_output/9473_test.log
 - /home/gerald/repositories/mGDB/logs/16-10-2023T13-07-32/gdb_output/9105_test.log
 - /home/gerald/repositories/mGDB/logs/16-10-2023T13-07-32/gdb_output/9443_test.log

<span style="color:#7FFF00">[INFO]</span> Added mappings: /home/gerald/repositories/mGDB/logs/16-10-2023T13-07-32/mappings.txt
<span style="color:#7FFF00">[INFO]</span> Added database: /home/gerald/repositories/mGDB/database/16-10-2023T13-07-32/sessions.txt
<span style="color:#7FFF00">[INFO]</span> Added gdb script contents for reference: /home/gerald/repositories/mGDB/logs/16-10-2023T13-07-32/debug_example_script.gdb
<span style="color:#7FFF00">[INFO]</span> Type the following command to follow all logs: tail -f /home/gerald/repositories/mGDB/logs/16-10-2023T13-07-32/gdb_output/*
</pre>

### 1.2 Showing Sessions
Running `show_sessions.sh` will show all current sessions managed by **mGDB** currently.
<pre>
root@gerald-ubuntu:/home/gerald/repositories/mGDB# ./show_sessions.sh 

<span style="color:#7FFF00">[INFO]</span> Current Sessions:
Session              | Arguments                                         
-------------------- | --------------------------------------------------
16-10-2023T13-13-57  | -l 9473 9443 -s gdb_scripts/debug_example_script.gdb 
16-10-2023T13-17-27  | -l 9105 -s gdb_scripts/debug_example_script.gdb
</pre>

### 1.3 Killing Sessions
Run `kill_sessions.sh` to end sessions managed by **mGDB** currently.

#### 1.3.1 Help (-h | --help)
<pre>
root@gerald-ubuntu:/home/gerald/repositories/mGDB# ./kill_sessions.sh -h
Usage: ./kill_sessions.sh [ -h ] ( -t | -a | -g )
  -h | --help                   Show this help message and exit         
  -t | --session-datetime       The gdb session identified by datetime  
  -a | --all                    Detaches all gdb processes from all sessions.
  -g | --global                 Detaches all gdb processes, including the ones not known in database.
</pre>

#### 1.3.2 Killing a Particular Session (-t | --session-datetime)
You can refer to the outputs of `./show_sessions.sh` to kill off a particular session.
<pre>
root@gerald-ubuntu:/home/gerald/repositories/mGDB# ./kill_sessions.sh -t 16-10-2023T13-13-57
<span style="color:#7FFF00">[INFO]</span> Detached gdb (10445) from test (9473)
<span style="color:#7FFF00">[INFO]</span> Detached gdb (10447) from test (9443)
<span style="color:#7FFF00">[INFO]</span> Removed session 16-10-2023T13-13-57 in database.
</pre>


#### 1.3.3 Killing all sessions managed by mGDB (-a | --all)
This feature just provides an easy way for lazy people like myself to kill off
all gdb processes in all sessions.
<pre>
root@gerald-ubuntu:/home/gerald/repositories/mGDB# ./kill_sessions.sh -a
<span style="color:#7FFF00">[INFO]</span> Detaching all gdb processes in session 16-10-2023T13-17-27...
<span style="color:#7FFF00">[INFO]</span> Detached gdb (10579) from test (9105)
<span style="color:#7FFF00">[INFO]</span> Removed session 16-10-2023T13-17-27 in database.
--------------------------------------------------------------
<span style="color:#7FFF00">[INFO]</span> Detaching all gdb processes in session 16-10-2023T13-30-54...
<span style="color:#7FFF00">[INFO]</span> Detached gdb (10835) from test (9473)
<span style="color:#7FFF00">[INFO]</span> Detached gdb (10838) from test (9443)
<span style="color:#7FFF00">[INFO]</span> Removed session 16-10-2023T13-30-54 in database.
--------------------------------------------------------------
</pre>

#### 1.3.4 Killing All GDB Processes (-g | --global)
**WARNING**: Please use this command only when you are very sure that you are the only one
doing the debugging on the system **or** if there are unwanted GDB processes hooking onto
your target processes.

The `-g | --global` option just provides an easy way to hard reset the enviroment such that there
won't be any gdb processes running anymore.
<pre>
root@gerald-ubuntu:/home/gerald/repositories/mGDB# ./kill_sessions.sh -g
<span style="color:#7FFF00">[INFO]</span> Detaching all gdb processes in session 16-10-2023T13-34-34...
<span style="color:#7FFF00">[INFO]</span> Detached gdb (10980) from test (9473)
<span style="color:#7FFF00">[INFO]</span> Detached gdb (10982) from test (9443)
<span style="color:#7FFF00">[INFO]</span> Removed session 16-10-2023T13-34-34 in database.
--------------------------------------------------------------
<span style="color:#7FFF00">[INFO]</span> Detaching all gdb processes in session 16-10-2023T13-34-37...
<span style="color:#7FFF00">[INFO]</span> Detached gdb (11048) from test (9105)
<span style="color:#7FFF00">[INFO]</span> Removed session 16-10-2023T13-34-37 in database.
--------------------------------------------------------------
<span style="color:#FF4500">[ERROR]</span> There are no gdb processes outside of known database.
</pre>

## 2. Extensions
As GDB's default commands are not the nicest and easiest to look at, there is a need
to extend its capabilities with the help of python scripting.

An example would be `info proc mappings` which shows you the different start addresses
and end addresses of a particular binary.

<pre>
(gdb) info proc mappings
process 9473
Mapped address spaces:

          Start Addr           End Addr       Size     Offset  Perms  objfile
      0x5589a58d7000     0x5589a58d8000     0x1000        0x0  r--p   /home/gerald/repositories/mGDB/test_binaries/test
      0x5589a58d8000     0x5589a58d9000     0x1000     0x1000  r-xp   /home/gerald/repositories/mGDB/test_binaries/test
      0x5589a58d9000     0x5589a58da000     0x1000     0x2000  r--p   /home/gerald/repositories/mGDB/test_binaries/test
      0x5589a58da000     0x5589a58db000     0x1000     0x2000  r--p   /home/gerald/repositories/mGDB/test_binaries/test
      0x5589a58db000     0x5589a58dc000     0x1000     0x3000  rw-p   /home/gerald/repositories/mGDB/test_binaries/test
      0x5589a5aa9000     0x5589a5aca000    0x21000        0x0  rw-p   [heap]
      <span style="color:#7FFF00">0x7f6a81c00000</span>     0x7f6a81c28000    0x28000        0x0  r--p   <span style="color:#7FFF00">/usr/lib/x86_64-linux-gnu/libc.so.6</span>
      0x7f6a81c28000     0x7f6a81dbd000   0x195000    0x28000  r-xp   /usr/lib/x86_64-linux-gnu/libc.so.6
      0x7f6a81dbd000     0x7f6a81e15000    0x58000   0x1bd000  r--p   /usr/lib/x86_64-linux-gnu/libc.so.6
      0x7f6a81e15000     0x7f6a81e19000     0x4000   0x214000  r--p   /usr/lib/x86_64-linux-gnu/libc.so.6
      0x7f6a81e19000     0x7f6a81e1b000     0x2000   0x218000  rw-p   /usr/lib/x86_64-linux-gnu/libc.so.6
</pre>

If I wanted the start address of `/usr/lib/x86_64-linux-gnu/libc.so.6`, I would have to manually look through the output
and probably assign `0x7f6a81c00000` to a variable. However, we want to be
able to do this programmatically.

Under `gdb_scripts/py_commands`, there are several useful commands such as:
- get_base_addr
- load_library_symbol
- strlen

To import in these commands, you can put the following line in your gdb script:
```commandline
source gdb_scripts/py_commands/<command_name>.py
```

Example of getting base address of a binary and printing its address using the return variable:
<pre>
(gdb) source gdb_scripts/py_commands/get_base_addr.py 
<span style="color:#7FFF00">[INFO]</span> Example usage of get_base_addr:
Template: get_base_addr <binary_path>
Eg. get_base_addr /usr/lib/example_lib.so
    - command name: get_base_addr
    - number of arguments: 1
    - ret variable in gdb: $get_base_addr_ret
      -> returns 0x0 on failure, otherwise a valid address

(gdb) get_base_addr /home/gerald/repositories/mGDB/test_binaries/test
<span style="color:#7FFF00">[INFO]</span> Found base address of /home/gerald/repositories/mGDB/test_binaries/test: 0x5589a58d7000

(gdb) printf "%p\n", $get_base_addr_ret
0x5589a58d7000
</pre>

## 3. Contributing
I am currently accepting pull requests for `gdb_scripts/py_commands` if you wish to implement
an extension that is useful for the community. Please follow the `gdb_scripts/py_commands/template.py`
as a guideline on writing extensions.


