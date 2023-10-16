#!/bin/bash

# Description:
# kill_sessions.sh sends a SIGINT to all gdb processes that are within a particular session

#-------Severity-------#
DEBUG="\033[0;94m[DEBUG]\033[0m"
INFO="\033[0;92m[INFO]\033[0m"
WARNING="\033[0;93m[WARNING]\033[0m"
ERROR="\033[0;91m[ERROR]\033[0m"
#----------------------#

function kill_session {

  local session_datetime="$1"

  if [[ ! -d $DATABASE_DIR || -z $(ls -A "$DATABASE_DIR") ]]; then
    echo -e "$ERROR There are currently no gdb sessions running!"
    return 1
  fi

  reference_file="$DATABASE_DIR/$session_datetime/sessions.txt"
  if [[ ! -f $reference_file ]]; then
    echo -e "$ERROR The given session datetime (${session_datetime}) does not exist!"
    echo -e "$ERROR Please run 'show_sessions.sh' to see a list of current sessions."
    return 1
  fi

  gdb_pids=()
	process_pids=()
	process_names=()
	while IFS=',' read -r gdb_pid process_pid process_name; do
		gdb_pids+=("$gdb_pid")
		process_pids+=("$process_pid")
		process_names+=("$process_name")
	done < "$reference_file"

  actual_running_gdb_pids=()
	actual_debugged_process_pids=()
	actual_debugged_process_names=()
	for i in "${!gdb_pids[@]}"; do
		ps "${gdb_pids[$i]}" > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			actual_running_gdb_pids+=("${gdb_pids[$i]}")
			actual_debugged_process_pids+=("${process_pids[$i]}")
			actual_debugged_process_names+=("${process_names[$i]}")
		else
			# Check if the debugged processes died
			ps "${process_pids[$i]}" > /dev/null 2>&1
			if [[ $? -ne 0 ]]; then
				echo -e "$WARNING gdb (${gdb_pids[$i]}) no longer exist as ${process_names[$i]} (${process_pids[$i]}) exited or crashed."

			# If the debugged process didn't die, it means that the gdb script exited early.
			else
				echo -e "$WARNING gdb (${gdb_pids[$i]}) is already detached from ${process_names[$i]} (${process_pids[$i]}) as the gdb script exited early."
			fi
		fi
	done

	if [[ ${#actual_running_gdb_pids[@]} -eq 0 ]]; then
		echo -e "$WARNING There are currently no gdb processes in this session datetime: $session_datetime"
		rm -rf "$DATABASE_DIR/$session_datetime"
		echo -e "$INFO Removed session $session_datetime in database."
		return 0
	fi

  remaining_gdb_pids=()
	remaining_debugged_process_pids=()
	remaining_debugged_process_names=()
	for i in "${!actual_running_gdb_pids[@]}"; do
		kill -s SIGINT "${actual_running_gdb_pids[$i]}"
		if [[ $? -ne 0 ]]; then
			echo -e "$ERROR Unable to detach gdb (${actual_running_gdb_pids[$i]}) from ${actual_debugged_process_names[$i]} (${actual_debugged_process_pids[$i]})!"
			remaining_gdb_pids+=("${actual_running_gdb_pids[$i]}")
			remaining_debugged_process_pids+=("${actual_debugged_process_pids[$i]}")
			remaining_debugged_process_names+=("${actual_debugged_process_names[$i]}")
		else
			echo -e "$INFO Detached gdb (${actual_running_gdb_pids[$i]}) from ${actual_debugged_process_names[$i]} (${actual_debugged_process_pids[$i]})"
		fi
	done
  # If there are still gdb processes within the session that are still hooking onto the target processes, then update the sessions.txt file.
	if [[ ${#remaining_gdb_pids[@]} -ne 0 ]]; then
		echo -e "$WARNING Unable to fully kill off all gdb processes within session $session_datetime!"
		echo "Remaining gdb PIDS:" "${remaining_gdb_pids[@]}"
		rm "$reference_file"
		for i in "${!remaining_gdb_pids[@]}"; do
			echo "${remaining_gdb_pids[$i]},${remaining_debugged_process_pids[$i]},${remaining_debugged_process_names[$i]}" >> "$reference_file"
		done
		echo -e "$INFO Updated session $session_datetime in database."
		echo -e "$WARNING Either run this script again or manually type the command: kill -s SIGINT [gdb pid]"
		return 0

	# If all gdb processes has been detached from the target processes successfully, then we delete the whole sessions datetime directory.
	else
		rm -rf "$DATABASE_DIR/$session_datetime"
		echo -e "$INFO Removed session $session_datetime in database."
	fi
  return 0
}

function kill_all_sessions {

  if [[ -z $(ls -A "$DATABASE_DIR") ]]; then
    echo -e "$ERROR There are no currently no sessions!"
    return 1
  fi

  for session_datetime_dir in "$CURR_DIR/database"/*; do
    if [[ ! -d "$session_datetime_dir" ]]; then
      continue
    fi
    session_datetime=$(basename "$session_datetime_dir")
    echo -e "$INFO Detaching all gdb processes in session $session_datetime..."
    kill_session "$session_datetime"
    echo "--------------------------------------------------------------"
  done
  return 0
}

function kill_global {
  kill_all_sessions
  # Check for gdb processes outside of known database
  other_gdb_processes=($(pidof gdb))
  if [[ "${#other_gdb_processes[@]}" -eq 0 ]];then
    echo -e "$ERROR There are no gdb processes outside of known database."
  else
    echo -e "$INFO Found other gdb processes outside of database:" "${other_gdb_processes[@]}"
    echo -e "$INFO Detaching these gdb processes..."

    # Try SIGHUP First
    kill -s SIGHUP "${other_gdb_processes[@]}"
    other_gdb_processes=($(pidof gdb))
    if [[ "${#other_gdb_processes[@]}" -eq 0 ]];then
      echo -e "$INFO Global reset complete!"
      return 0
    fi
    # If it didn't work, try SIGINT
    kill -s SIGINT "${other_gdb_processes[@]}"
    other_gdb_processes=($(pidof gdb))
    if [[ "${#other_gdb_processes[@]}" -eq 0 ]];then
      echo -e "$INFO Global reset complete!"
      return 0
    fi
    # If it didn't work, try SIGKILL (WARNING - May end up causing a seg fault or core dump on debugged process)
    kill -s SIGKILL "${other_gdb_processes[@]}"
    other_gdb_processes=($(pidof gdb))
    if [[ "${#other_gdb_processes[@]}" -eq 0 ]];then
      echo -e "$INFO Global reset complete!"
      return 0
    fi
  fi
}

# Function to check if a value is in the "dd-mm-yyyyTHH-MM-SS" datetime format
function is_datetime {
    local datetime="$1"
    if [[ "$datetime" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}T[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 0  # Valid datetime format
    else
        return 1  # Invalid datetime format
    fi
}

function usage {
    echo "Usage: $0 [ -h ] ( -t | -a | -g )"
    printf "%-30s  %-40s\n" "  -h | --help" "Show this help message and exit"
    printf "%-30s  %-40s\n" "  -t | --session-datetime" "The gdb session identified by datetime"
    printf "%-30s  %-40s\n" "  -a | --all" "Detaches all gdb processes from all sessions."
    printf "%-30s  %-40s\n" "  -g | --global" "Detaches all gdb processes, including the ones not known in database."
    exit 1
}

# Checks
if [[ $EUID -ne 0 ]]; then
	echo -e "$ERROR Please run this script as root!"
	exit 1
fi

h_option=false
t_option=false
a_option=false
g_option=false
SESSION_DATETIME=""
while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--session-datetime)
        if [[ -z "$2" || "$2" =~ ^- ]]; then
          echo -e "$ERROR (-t | --session-datetime) No datetime was given at all!"
          usage
          exit 1
        fi
        if ! is_datetime "$2"; then
          echo -e "${ERROR} (-t | --session-datetime) Expected 'dd-mm-yyyyTHH-MM-SS' but received invalid datetime format!"
          exit 1
        fi
        t_option=true
        SESSION_DATETIME="$2"
        shift 2
        ;;
      -a|--all)
        a_option=true
        shift
        ;;
      -g|--global)
        g_option=true
        shift
        ;;
      -h|--help)
        h_option=true
        shift
        ;;
      *)
        echo -e "${ERROR} Invalid argument specifier! Please refer to usage!"
        usage
        exit 1
        ;;
    esac
done

# Check if -h is specified, regardless of other options
if [ "$h_option" = true ]; then
    usage
    exit 1
fi

# Check that at least one option is specified
if [[ "$t_option" = false && "$a_option" = false && "$g_option" = false ]]; then
    echo -e "$ERROR Either -t (--session-datetime), -a (--all) or g (--global) must be specified."
    usage
    exit 1
fi

# Check that -t, -a and -g are mutually exclusive
if [[ "$t_option" = true && "$a_option" = true &&  "$g_option" = false ]]; then
    echo -e "$ERROR -t (--session-datetime) and -a (--all) are mutually exclusive options."
    usage
    exit 1
fi
if [[ "$t_option" = true && "$a_option" = false &&  "$g_option" = true ]]; then
    echo -e "$ERROR -t (--session-datetime) and -g (--global) are mutually exclusive options."
    usage
    exit 1
fi
if [[ "$t_option" = false && "$a_option" = true &&  "$g_option" = true ]]; then
    echo -e "$ERROR -a (--all) and -g (--global) are mutually exclusive options."
    usage
    exit 1
fi
if [[ "$t_option" = true && "$a_option" = true &&  "$g_option" = true ]]; then
    echo -e "$ERROR -t (--session-datetime),-a (--all) and -g (--global) are mutually exclusive options."
    usage
    exit 1
fi


# GLOBALS
CURR_DIR=$(dirname "$(realpath "$0")")
DATABASE_DIR=$CURR_DIR/database

# Entry point
if [[ "$t_option" = true && "$a_option" = false && "$g_option" = false ]]; then
  kill_session "$SESSION_DATETIME"
elif [[  "$t_option" = false && "$a_option" = true && "$g_option" = false ]]; then
  kill_all_sessions
elif [[  "$t_option" = false && "$a_option" = false && "$g_option" = true ]]; then
  kill_global
fi


