import gdb
import os
import sys
import json
from typing import *
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from utils.messenger import Severity, Messenger


class JsonGetValueFromKey(gdb.Command):

    def __init__(self):

        """
        Please follow this template and change the following variables:
            1. self.__command_name
            2. self.__num_args
            3. self.__ret_variable_gdb
        """
        self.__command_name = "json_get_value_from_key"
        self.__num_args = 2
        self.__ret_variable_gdb = "${}_ret".format(self.__command_name)

        self.__messenger = Messenger()
        super(JsonGetValueFromKey, self).__init__(self.__command_name, gdb.COMMAND_USER)
        self.__usage()
        return

    def __usage(self) -> None:
        self.__messenger.print_message(Severity.INFO, "Example usage of {}:".format(self.__command_name))
        print("Template: {} {} {}".format(self.__command_name, "<json string address>", "<key>"))
        print("Eg. {} {} {}".format(self.__command_name, "$json_string_addr", "data.data.ppid"))
        print("Eg. {} {} {}".format(self.__command_name, "0x55fba5e821ab", "type"))
        print("Eg. {} {} {}".format(self.__command_name, "93907404636198", "id"))
        print("    - command name: {}".format(self.__command_name))
        print("    - number of arguments: {}".format(self.__num_args))
        print("    - ret variable in gdb: {}".format(self.__ret_variable_gdb))
        print("      -> returns an 1 on failure, otherwise 0 on success")
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

        json_str_addr = 0x0
        # if the argument passed in is a gdb variable
        try:
            if arg_tokens[0].startswith("$"):
                value = str(gdb.parse_and_eval(arg_tokens[0]))
                if value.startswith("0x"):
                    json_str_addr = int(value.split()[0], base=16)
                else:
                    json_str_addr = int(value.split()[0], base=10)

            # if the argument passed in is a hexadecimal address
            elif arg_tokens[0].startswith("0x"):
                json_str_addr = int(arg_tokens[0], base=16)

            # if the argument passed in is a decimal address
            else:
                json_str_addr = int(arg_tokens[0], base=10)
        except ValueError:
            self.__messenger.print_message(Severity.ERROR, "Expected a gdb variable or numeric "
                                                           "but got something else instead!")
            gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
            return

        json_str = u""
        length = 0
        try:
            while True:
                char = gdb.parse_and_eval("*(char *){}".format(json_str_addr + length))
                if char == 0:
                    break
                try:
                    json_str += chr(char)
                except ValueError:
                    pass
                length += 1
        except gdb.MemoryError:
            gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
            return

        # After assembling the json string, verify that the json string is valid
        try:
            json_object = json.loads(json_str)

            keys = [key.strip() for key in arg_tokens[1].split(".")]

            # Check for empty key
            for key in keys:
                if key == "":
                    self.__messenger.print_message(Severity.ERROR, "Empty Key seen in {}: {}".format(arg_tokens[1],
                                                                                                     keys))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return

            if len(keys) > 5:
                self.__messenger.print_message(Severity.ERROR, "Too many parent-child keys! (Currently supports <= 5)")
                gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                return

            # Get the value from the key
            if len(keys) == 1:
                if keys[0] not in json_object:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                self.__messenger.print_message(Severity.INFO, "{}: {}".format(arg_tokens[1],
                                                                              json_object[keys[0]]))

            elif len(keys) == 2:
                if keys[0] not in json_object:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[1] not in json_object[keys[0]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                self.__messenger.print_message(Severity.INFO, "{}: {}".format(arg_tokens[1],
                                                                              json_object[keys[0]][keys[1]]))

            elif len(keys) == 3:
                if keys[0] not in json_object:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[1] not in json_object[keys[0]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[2] not in json_object[keys[0]][keys[1]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                self.__messenger.print_message(Severity.INFO, "{}: {}".format(arg_tokens[1],
                                                                              json_object[keys[0]][keys[1]][keys[2]]))

            elif len(keys) == 4:
                if keys[0] not in json_object:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[1] not in json_object[keys[0]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[2] not in json_object[keys[0]][keys[1]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[3] not in json_object[keys[0]][keys[1]][keys[2]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                self.__messenger.print_message(Severity.INFO, "{}: {}".format(arg_tokens[1],
                                                                              json_object[keys[0]][keys[1]][keys[2]][keys[3]]))

            elif len(keys) == 5:
                if keys[0] not in json_object:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[1] not in json_object[keys[0]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[2] not in json_object[keys[0]][keys[1]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[3] not in json_object[keys[0]][keys[1]][keys[2]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                if keys[4] not in json_object[keys[0]][keys[1]][keys[2]][keys[3]]:
                    self.__messenger.print_message(Severity.ERROR,
                                                   "Key: {} does not exist!".format(keys[0]))
                    gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
                    return
                self.__messenger.print_message(Severity.INFO, "{}: {}".format(arg_tokens[1],
                                                                              json_object[keys[0]][keys[1]][keys[2]][keys[3]][keys[4]]))

        except json.JSONDecodeError:
            self.__messenger.print_message(Severity.ERROR, "The string @ {} is not a valid json object!".format(json_str_addr))
            gdb.execute("set {} = 1".format(self.__ret_variable_gdb))
            return

        gdb.execute("set {} = 0".format(self.__ret_variable_gdb))
        return


JsonGetValueFromKey()
