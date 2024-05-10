import sys
import argparse
import os
import re
from enum import Enum


class Severity(Enum):
    DEBUG = "\033[0;94m[DEBUG]\033[0m "
    INFO = "\033[0;92m[INFO]\033[0m "
    WARNING = "\033[0;93m[WARNING]\033[0m "
    ERROR = "\033[0;91m[ERROR]\033[0m "


class Messenger:

    def __init__(self,
                 verbosity_level: int = 1):
        self.__verbosity_level = verbosity_level
        return

    def print_message(self,
                      sev: Severity,
                      message: str = "") -> None:
        """
        Utility function to print messages of different severity levels

        :param sev: A Severity Enum
        :param message: The string to be printed
        :return: None
        """

        # If verbosity is default, then ignore all the debug messages
        if self.__verbosity_level == 1 and sev == Severity.DEBUG:
            return

        # Prints all messages under the sun
        print(sev.value + message)
        return


def main():
    if not os.path.exists(args.input_file):
        messenger.print_message(Severity.ERROR, "Input file does not exist!")
        return
    filename, sep, ext = args.input_file.partition('.')
    output_file = filename + "_indent" + sep + ext

    f_input = open(args.input_file, "r")
    f_output = open(output_file, "w")
    start_tag = "<#__start__#>"
    end_tag = "<#__end__#>"
    instruction_regex = re.compile(r'^.*:\s+(\w+).*$')

    has_found_start_tag = False
    indent = 4
    for line in f_input:
        line = line.strip()
        if start_tag == line:
            has_found_start_tag = True
        if end_tag == line:
            break
        if not has_found_start_tag:
            continue

        match = instruction_regex.search(line)
        if not match:
            continue
        if match.group(1).strip() == "call":
            f_output.write('  ' * indent)
            f_output.write(line + "\n")
            f_output.flush()
            indent += 1

        elif match.group(1).strip() == "ret":
            f_output.write('  ' * indent)
            f_output.write(line + "\n")
            f_output.flush()
            indent -= 1

    f_input.close()
    f_output.close()
    messenger.print_message(Severity.INFO, "Finished writing to {}".format(output_file))
    return


if __name__ == "__main__":
    # Arguments
    arg_parser = argparse.ArgumentParser(description="Outputs Parent-Child Function Call Relationship",
                                         epilog="Developed by Gerald Lim Wee Koon (github: mathscantor)",
                                         formatter_class=argparse.RawTextHelpFormatter)
    arg_parser.add_argument("-i", "--input-file", dest='input_file', metavar="", type=str, required=True,
                            help="GDB log file which contains all the instructions "
                                 "of stepping through from start tag to end tag")
    args = arg_parser.parse_args()
    messenger = Messenger()
    main()
