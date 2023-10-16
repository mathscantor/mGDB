import gdb
import os
import sys
import re
from typing import *
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from utils.messenger import Severity, Messenger


class GetBaseAddr(gdb.Command):

    def __init__(self):

        """
        Please follow this template and change the following variables:
            1. self.__command_name
            2. self.__num_args
            3. self.__ret_variable_gdb
        """
        self.__command_name = "get_base_addr"
        self.__num_args = 1
        self.__ret_variable_gdb = "${}_ret".format(self.__command_name)

        self.__messenger = Messenger()
        super(GetBaseAddr, self).__init__(self.__command_name, gdb.COMMAND_USER)
        self.__usage()
        return

    def __usage(self) -> None:
        self.__messenger.print_message(Severity.INFO, "Example usage of {}:".format(self.__command_name))
        print("Template: {} {}".format(self.__command_name, "<library_name>"))
        print("Eg. {} {}".format(self.__command_name, "example_lib.so"))
        print("    - command name: {}".format(self.__command_name))
        print("    - number of arguments: {}".format(self.__num_args))
        print("    - ret variable in gdb: {}".format(self.__ret_variable_gdb))
        print("      -> returns 0x0 on failure, otherwise a valid address")
        return

    def __check_arguments(self,
                          arg_tokens: List[str]) -> bool:
        if len(arg_tokens) != self.__num_args:
            self.__messenger.print_message(Severity.ERROR, "{}: Expected {} arguments but "
                                                           "got {} arguments instead!".format(self.__command_name,
                                                                                              self.__num_args,
                                                                                              len(arg_tokens)))
            return False
        return True

    def invoke(self,
               args: str,
               from_tty: bool = False) -> None:
        arg_tokens = [arg.strip() for arg in args.split()]
        if not self.__check_arguments(arg_tokens):
            self.__usage()
            return

        binary_name = arg_tokens[0]
        output = gdb.execute("info proc mappings", to_string=True)
        mappings = gdb.execute("info proc mappings", to_string=True).split("\n")[4:]
        for mapping in mappings:
            tokens = re.split(r"\s+", mapping.strip())
            if len(tokens) != 6:
                continue
            if binary_name == os.path.basename(tokens[5]):
                self.__messenger.print_message(Severity.INFO, "Found base address of {}!".format(binary_name))
                gdb.execute("set {} = {}".format(self.__ret_variable_gdb, tokens[0]))
                return

        self.__messenger.print_message(Severity.ERROR, "Unable to get base address of {}!\n".format(binary_name))
        gdb.execute("set {} = 0x0".format(self.__ret_variable_gdb))
        return


GetBaseAddr()
