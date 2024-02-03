import gdb
import os
import sys
import re
import json
import ast
from typing import *
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from utils.messenger import Severity, Messenger


class Mgrep(gdb.Command):

    def __init__(self):

        """
        Please follow this template and change the following variables:
            1. self.__command_name
            2. self.__num_args
            3. self.__ret_variable_gdb
        """
        self.__command_name = "mgrep"
        self.__num_args = 1
        self.__ret_variable_gdb = "${}_ret".format(self.__command_name)

        self.__messenger = Messenger()
        super(Mgrep, self).__init__(self.__command_name, gdb.COMMAND_USER)
        self.__usage()
        return

    def __usage(self) -> None:
        self.__messenger.print_message(Severity.INFO, "Example usage of {}:".format(self.__command_name))
        print("Template: {} {}".format(self.__command_name, "<expression>"))
        print("Eg. {} {}".format(self.__command_name, "string_to_find"))
        print("    - command name: {}".format(self.__command_name))
        print("    - number of arguments: {}".format(self.__num_args))
        print("    - ret variable in gdb: {}".format(self.__ret_variable_gdb))
        print(r"      -> returns an array of addresses on success and {0x0} on failure.")
        print("    - Getting size of array returned: sizeof($mgrep_ret)/sizeof(*$mgrep_ret)")
        return

    def __check_arguments(self,
                          args: str) -> bool:
        pattern = r'^[\'"](.+)[\'"]$'
        match = re.match(pattern, args)
        if not match:
            self.__messenger.print_message(Severity.ERROR, 
                                           "Please encapsulate your string with double quotes (\"\")\n" 
                                           "If you want to find patterns with \", remember to escape with \\")
            return False

        return True
    
    def __get_memory_sections(self) -> Dict[str, Dict[str, str]]:
        
        '''
        Memory Section JSON format:
        {
            "/home/kali/Desktop/mGDB/test_binaries/test": {
                "start_addr": "0x55680ce23000",
                "end_addr": "0x55680ce23fff"
            },
            "[heap]": {
                "start_addr": "0x55680ecd7000",
                "end_addr": "0x55680ecf7fff"
            },
            "/usr/lib/x86_64-linux-gnu/libc.so.6": {
                "start_addr": "0x7fe3c8b25000",
                "end_addr": "0x7fe3c8b26fff"
            },
            .
            .
            .
        }
        '''
        memory_sections = dict()
        mappings = gdb.execute("info proc mappings", to_string=True).split("\n")[4:]
        previous_section = ""
        for map in mappings:
            map_tokens = re.split(r"\s+", map.strip())

            # Not interested in memory locations without any libraries or binaries
            if len(map_tokens) != 6:
                continue
            
            # Can't read this section anyways
            if map_tokens[5] == "[vvar]":
                continue
            
            # Not interested in memory locations that is not readable
            if not map_tokens[4].startswith('r'):
                continue
            
            # Add binary path as key if we haven't already
            if map_tokens[5] not in memory_sections:
                memory_sections[map_tokens[5]] = {"start_addr": map_tokens[0],
                                                  "end_addr": map_tokens[1]}

            # Note that linux maps memory by [x, y) format. Inclusive of x but excluding y.
            # See Here: https://stackoverflow.com/questions/34819167/gdb-find-command-error-warning-unable-to-access-x-bytes-of-target-memory-at-y
            memory_sections[map_tokens[5]]["end_addr"] = hex(int(map_tokens[1], 16) - 1)
        
        #print(json.dumps(memory_sections, indent=4))
        return memory_sections
    
    def __find_pattern(self, 
                       memory_sections: Dict[str, Dict[str, str]],
                       expr: str) -> List[str]:
        
        match_list = list()
        bytes_expr = ', '.join([f"0x{ord(char):02x}" for char in expr])
        for section_name in memory_sections:
            results = gdb.execute("find /b {}, {}, {}".format(memory_sections[section_name]["start_addr"],
                                                              memory_sections[section_name]["end_addr"],
                                                              bytes_expr), 
                                                              to_string=True)
            results_tokens = results.split("\n")
            if results_tokens[-2] == "Pattern not found.":
                continue

            for addr in results_tokens:
                if "pattern" in addr:
                    break
                match_list.append(addr.split()[0])

        return match_list
    
    def __get_binary_path_from_addr(self,
                                    addr: str,
                                    memory_sections) -> str:
        
        for section, addr_range in memory_sections.items():
            start_addr = int(addr_range["start_addr"], 16)
            end_addr = int(addr_range["end_addr"], 16)
            if start_addr <= int(addr, 16) <= end_addr:
                return section

        return ""
    
    def __pretty_print_pattern_match(self,
                                     memory_sections: Dict[str, Dict[str, str]],
                                     match_list: List[str]) -> None:
        
        if len(match_list) == 0:
            self.__messenger.print_message(Severity.INFO, "Found 0 matches!")
            return

        self.__messenger.print_message(Severity.INFO, "Found {} matches at:".format(len(match_list)))
        for addr in match_list:
            addr_and_string = ' '.join(gdb.execute("x/s {}".format(addr), to_string=True).strip("\n").split())
            binary_path = self.__get_binary_path_from_addr(addr, memory_sections)
            offset_from_base = hex(int(addr, 16) - int(memory_sections[binary_path]["start_addr"], 16))
            print("\t[+] {} + {} -> {}".format(binary_path, 
                                               offset_from_base,
                                               addr_and_string))

        return

    def invoke(self,
               args: str,
               from_tty: bool = False) -> None:

        if not self.__check_arguments(args):
            self.__usage()
            gdb.execute("set {} = {}".format(self.__ret_variable_gdb, "{0x0}"))
            return

        # self.__messenger.print_message(Severity.INFO, "Received Argument value: {}".format(args))
        memory_sections = self.__get_memory_sections()
        expr = args.split('"')[1]
        match_list = self.__find_pattern(memory_sections, expr)
        self.__pretty_print_pattern_match(memory_sections, match_list)

        if len(match_list) == 0:
            gdb.execute("set {} = {}".format(self.__ret_variable_gdb, "{0x0}"))
            return
        
        ret_variable_expr = "{" + ", ".join(match_list) + "}"
        gdb.execute("set {} = {}".format(self.__ret_variable_gdb, ret_variable_expr))
        return


Mgrep()
