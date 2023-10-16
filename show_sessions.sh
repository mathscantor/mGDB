#!/bin/bash

# Description:
# show_sessions.sh prints the arguments used when creating a session of gdb processes.

#-------Severity-------#
DEBUG="\033[0;94m[DEBUG]\033[0m"
INFO="\033[0;92m[INFO]\033[0m"
WARNING="\033[0;93m[WARNING]\033[0m"
ERROR="\033[0;91m[ERROR]\033[0m"
#----------------------#

#TODO: reference $DATABASE_DIR/$session_datetime/arguments.txt and sessions.txt and pretty print

function pretty_print_session {

  local session_datetime="$1"
  reference_file="$DATABASE_DIR/$session_datetime/sessions.txt"
  arguments_file="$DATABASE_DIR/$session_datetime/arguments.txt"

  gdb_pids=()
	process_pids=()
	process_names=()
	while IFS=',' read -r gdb_pid process_pid process_name; do
		gdb_pids+=("$gdb_pid")
		process_pids+=("$process_pid")
		process_names+=("$process_name")
	done < "$reference_file"

  printf "%-20s | " "$session_datetime"
  printf "%-30s\n" "$(cat "$arguments_file")"

}

function pretty_print_all_sessions {

  if [[ -z $(ls -A "$DATABASE_DIR") ]]; then
    echo -e "$ERROR There are no currently no sessions!"
    exit 1
  fi

  echo ""
	echo -e "$INFO Current Sessions:"
	printf "%-20s | %-50s\n" "Session" "Arguments"
	printf "%-20s | %-30s\n" "--------------------" "--------------------------------------------------"
  for session_datetime_dir in "$CURR_DIR/database"/*; do
    if [[ ! -d "$session_datetime_dir" ]]; then
      continue
    fi
    session_datetime=$(basename "$session_datetime_dir")
    pretty_print_session "$session_datetime"
  done
  echo ""
}

# GLOBALS
CURR_DIR=$(dirname "$(realpath "$0")")
DATABASE_DIR=$CURR_DIR/database

# Entry point
pretty_print_all_sessions