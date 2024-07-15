#!/bin/bash

# Description:
# start_sessions.sh provides a way to handle debugging on multiple running processes
# by spawning multiple gdb processes to handle them gracefully.
# These gdb processes are managed per session basis.

#-------Severity-------#
DEBUG="\033[0;94m[DEBUG]\033[0m"
INFO="\033[0;92m[INFO]\033[0m"
WARNING="\033[0;93m[WARNING]\033[0m"
ERROR="\033[0;91m[ERROR]\033[0m"
#----------------------#

function pretty_print_status {
	echo ""
	echo -e "$INFO Debugging Session Mappings ($CURR_DATETIME)"
  if [[ "$n_option" = true || "$l_option" = true ]]; then
    printf "%-20s | %-20s | %-20s\n" "--------------------" "--------------------" "--------------------"
    printf "%-20s | %-20s | %-20s\n" "GDB PID" "PROCESS PID" "PROCESS NAME"
    printf "%-20s | %-20s | %-20s\n" "--------------------" "--------------------" "--------------------"

    len="${#target_process_pids[@]}"
    for (( i=0; i<$len; i++ )); do
      printf "%-20s | %-20s | %-20s\n" "${gdb_pids[$i]}" "${target_process_pids[$i]}" "${target_process_names[$i]}"
    done
    echo ""
    echo "All gdb output is redirected to:"
    for (( i=0; i<$len; i++ )); do
      printf " - $LOGS_DIR/gdb_output/${target_process_pids[$i]}_${target_process_names[$i]}.log\n"
    done
    echo ""

  elif [[ "$pp_option" = true && "$t_option" = true ]]; then
    printf "%-20s | %-20s | %-20s\n" "--------------------" "--------------------" "--------------------"
    printf "%-20s | %-20s | %-20s\n" "GDB PID" "THREAD TID" "PROCESS NAME"
    printf "%-20s | %-20s | %-20s\n" "--------------------" "--------------------" "--------------------"
    len="${#target_thread_tids[@]}"
    for (( i=0; i<$len; i++ )); do
      printf "%-20s | %-20s | %-20s\n" "${gdb_pids[$i]}" "${target_thread_tids[$i]}" "${target_process_names[$i]}"
    done
    echo ""
    echo "All gdb output is redirected to:"
    for (( i=0; i<$len; i++ )); do
      printf " - $LOGS_DIR/gdb_output/thread_${target_thread_tids[$i]}_${target_process_names[$i]}.log\n"
    done
    echo ""
  fi
}

function run_multiple_gdb_instances {

  echo -e "$INFO GDB batch attach delay: ${DELAY_TIME}s"
  sleep $DELAY_TIME

  # For targeting multiple processes / process via name or list
  if [[ "$n_option" = true || "$l_option" = true ]]; then
    for pid in "${target_process_pids[@]}"; do
      process_name=$(ps -p "$pid" -o comm=)
      $GDB_PATH --batch --command=$GDB_SCRIPT -p $pid > $LOGS_DIR/gdb_output/"$pid"_"$process_name".log 2>&1 &

      gdb_pid=$!
      if [[ $? -ne 0 ]]; then
        echo -e "$ERROR Error in attaching gdb to $PROCESS_NAME($pid)"
      else
        gdb_pids+=("${gdb_pid}")
        target_process_names+=("${process_name}")
      fi
    done
    for i in "${!gdb_pids[@]}"; do
		  echo "${gdb_pids[$i]},${target_process_pids[$i]},${target_process_names[$i]}" >> $reference_file
    done
    echo -e "$INFO Added database: $reference_file"

  # For target speicfic threads in a specific process
  elif [[ "$pp_option" = true && "$t_option" = true ]]; then
    process_name=$(ps -p "${target_parent_process_pid}" -o comm=)
    for tid in "${target_thread_tids[@]}"; do
      $GDB_PATH --batch --command=$GDB_SCRIPT -p $tid > $LOGS_DIR/gdb_output/thread_"$tid"_"$process_name".log 2>&1 &
      gdb_pid=$!
      if [[ $? -ne 0 ]]; then
        echo -e "$ERROR Error in attaching gdb to thread $tid of $process_name($target_parent_process_pid)"
      else
        gdb_pids+=("${gdb_pid}")
        target_process_names+=("${process_name}")
      fi
    done
    for i in "${!gdb_pids[@]}"; do
		  echo "${gdb_pids[$i]},${target_thread_tids[$i]},$process_name" >> $reference_file
    done
    echo -e "$INFO Added database: $reference_file"
  fi

  # Add the full arguments used into a file for printing later
  echo "$arguments" > "$DATABASE_DIR/$CURR_DATETIME/arguments.txt"

	pretty_print_status
	pretty_print_status > $LOGS_DIR/mappings.txt
	echo -e "$INFO Added mappings: $LOGS_DIR/mappings.txt"

	gdb_script_filename=$(basename "$GDB_SCRIPT")
	cp $GDB_SCRIPT $LOGS_DIR/$gdb_script_filename
	echo -e "$INFO Added gdb script contents for reference: $LOGS_DIR/$gdb_script_filename"	
	echo -e "$INFO Type the following command to follow all logs: tail -f $LOGS_DIR/gdb_output/*"
	exit 0
}

function has_duplicate_pid {
  local process_pids_1=("${!1}")  # Array 1
  local process_pids_2=("${!2}")  # Array 2
  local gdb_pids_2=("${!3}") # gdb pids related to array 2
  local process_names_2=("${!4}") # process names related to array 2
  local duplicate_pids=()

   # Loop through elements in Array 1
  for i in "${!process_pids_1[@]}"; do
    # Loop through elements in Array 2
    for j in "${!process_pids_2[@]}"; do
        # Compare elements for equality
        if [ "${process_pids_1[$i]}" == "${process_pids_2[$j]}" ]; then
          echo -e "$ERROR GDB (${gdb_pids_2[$j]}) is already debugging ${process_names_2[$i]} (${process_pids_1[$i]})!"
          duplicate_pids+=("${process_pids_1[$i]}")
        fi
    done
  done

  # if there are duplicate pids, return code 0
  if [[ ${#duplicate_pids[@]} -ne 0 ]]; then
    return 0
  fi
  #else return code 1
  return 1
}

function check_user_args {

  # if gdb script does not exist, exit 1
	if [[ ! -f $GDB_SCRIPT ]]; then
		echo -e "$ERROR gdb script does not exist: $GDB_SCRIPT"
		exit 1
	fi

  if [[ "$pp_option" = true && "$t_option" = true ]]; then
    non_existent_tids=()
    for tid in ${target_thread_tids[@]}; do
      if [ ! -d /proc/$target_parent_process_pid/task/$tid ]; then
        non_existent_tids+=("${tid}")
      fi
    done
    if [[ "${#non_existent_tids[@]}" -ne 0 ]]; then
      echo -e "$ERROR The following thread TIDs of the parent process ($target_parent_process_pid) does not exist:" "${non_existent_tids[@]}"
      echo -e "$INFO Available Thread TIDs: "$(ls /proc/$target_parent_process_pid/task -1 | tail -n +2 | paste -sd " ")
      exit 1
    fi
  else
    # if there are 0 targeted pids, exit 1
    if [[ ${#target_process_pids[@]} -eq 0 ]]; then
      if [[ "$n_option" = true && "$l_option" = false ]]; then
        echo -e "$ERROR There are currently no running $PROCESS_NAME processes!"
        exit 1
      elif [[ "$n_option" = false && "$l_option" = true ]]; then
        echo -e "$ERROR No running processes were given!"
        exit 1
      fi
    fi

    # check if any of the targeted pids actually do not exist. If so, exit early and throw error
    non_existent_pids=()
    for i in "${!target_process_pids[@]}"; do
      ps "${target_process_pids[$i]}" > /dev/null 2>&1
      if [[ $? -ne 0 ]]; then
        non_existent_pids+=("${target_process_pids[$i]}")
      fi
    done
    if [[ "${#non_existent_pids[@]}" -ne 0 ]]; then
      echo -e "$ERROR The following PIDs does not exist:" "${non_existent_pids[@]}"
      exit 1
    fi
  fi

  # No need to check if there isn't a database directory
  if [[ ! -d $CURR_DIR/database ]]; then
    return 0
  fi

  # Crawl thorugh each session_datetime directory and check if there are any current gdb process
  # that are already attached to the targeted processes
  for session_datetime_dir in "$CURR_DIR/database"/*; do
    if [[ ! -d "$session_datetime_dir" ]]; then
      continue
    fi
    if [[ ! -f "$session_datetime_dir/sessions.txt" ]]; then
      continue
    fi
    session_datetime=$(basename "$session_datetime_dir")

    actual_running_gdb_pids=()
    actual_debugged_process_pids=()
    actual_debugged_process_names=()
		while IFS=',' read -r gdb_pid process_pid process_name; do
			actual_running_gdb_pids+=("$gdb_pid")
			actual_debugged_process_pids+=("$process_pid")
			actual_debugged_process_names+=("$process_name")
		done < "$session_datetime_dir/sessions.txt"

		if [[ ${#actual_running_gdb_pids[@]} -ne 0 ]]; then
      # if the requested target pid is already being debugged by a gdb process, return error later
      if has_duplicate_pid target_process_pids[@] actual_debugged_process_pids[@] actual_running_gdb_pids[@] actual_debugged_process_names[@]; then
        echo -e "$ERROR Please run the following command first: ./kill_sessions.sh -t $session_datetime"
        exit 1
      fi
		fi
  done
  return 0
}

# Function to check if a value is numeric
function is_numeric {
  local value="$1"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
      return 0  # Numeric
  else
      return 1  # Not numeric
  fi
}

# Function to check if a string is a valid float
function is_float {
  if [[ $1 =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; then
    return 0 # FLoat
  else
    return 1 # Not Float
  fi
}

function usage {
    echo "Usage: $0 [ -h ] ( -n | -l ) -s [ -w ] [ -d ]"
    printf "%-30s  %-40s\n" "  -h  | --help" "Show this help message and exit"
    printf "%-30s  %-40s\n" "  -n  | --process-name" "The name of the process(es)"
    printf "%-30s  %-40s\n" "  -l  | --pid-list" "A list of pids"
    printf "%-30s  %-40s\n" "  -pp | --parent-pid" "The parent PID (used in conjunction with -t | --tid-list)"
    printf "%-30s  %-40s\n" "  -t  | --tid-list" "A list of tids (used in conjunction with -pp | --parent-pid)"
    printf "%-30s  %-40s\n" "  -s  | --script" "Path to gdb script"
    printf "%-30s  %-40s\n" "  -w  | --wait" "To wait on a process to spawn."
    printf "%-30s  %-40s\n" "             " "This only works with (-n | --process-name)"
    printf "%-30s  %-40s\n" "  -d  | --delay" "Delays the gdb attcachment in seconds. (integer/float)"
    exit 1
}


# Check UID
if [[ $EUID -ne 0 ]]; then
	echo -e "$ERROR Please run this script as root!"
	exit 1
fi

h_option=false
n_option=false
l_option=false
pp_option=false
t_option=false
s_option=false
w_option=false
d_option=false
GDB_SCRIPT=""
DELAY_TIME=0
PID_LIST=()
TID_LIST=()
# Keep track of our arguments so that we can print it out in -m | --show-sessions
arguments=""
while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--process-name)
        if [[ -z "$2" || "$2" =~ ^- ]]; then
          echo -e "$ERROR (-n | --process-name) No process name was given at all!"
          usage
          exit 1
        fi
        arguments+="$1 $2 "
        n_option=true
        PROCESS_NAME=$2
        shift 2
        ;;
      -l|--pid-list)
        if [[ -z "$2" || "$2" =~ ^- ]]; then
          echo -e "$ERROR (-l | --pid-list) No PIDs were given at all!"
          usage
          exit 1
        fi
        arguments+="$1 "
        l_option=true
        shift
        while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
          if ! is_numeric "$1"; then
            echo -e "$ERROR (-l | --pid-list) Expected numeric PID but got '$1' instead!"
            usage
            exit 1
          fi
          PID_LIST+=("$1")
          arguments+="$1 "
          shift
        done
        ;;
      -pp|--parent-pid)
        if [[ -z "$2" || "$2" =~ ^- ]]; then
          echo -e "$ERROR (-pp | --parent-pid) No parent PID was given at all!"
          usage
          exit 1
        fi
        arguments+="$1 $2 "
        pp_option=true
        PARENT_PID=$2
        shift 2
        ;;
      -t|--tid-list)
        if [[ -z "$2" || "$2" =~ ^- ]]; then
          echo -e "$ERROR (-t | --tid-list) No TIDs were given at all!"
          usage
          exit 1
        fi
        arguments+="$1 "
        t_option=true
        shift
        while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
          if ! is_numeric "$1"; then
            echo -e "$ERROR (-l | --pid-list) Expected numeric PID but got '$1' instead!"
            usage
            exit 1
          fi
          TID_LIST+=("$1")
          arguments+="$1 "
          shift
        done
        ;;
      -s|--script)
        if [[ -z "$2" || "$2" =~ ^- ]]; then
          echo -e "$ERROR (-s | --script) No gdb script path was provided!"
          usage
          exit 1
        fi
        arguments+="$1 $2 "
        s_option=true
        GDB_SCRIPT="$2"
        shift 2
        ;;
      -w|--wait)
        arguments+="$1 "
        w_option=true
        shift
        ;;
      -d|--delay)
        arguments+="$1 $2 "
        d_option=true
        DELAY_TIME="$2"
        shift 2
        ;;
      -h|--help)
        h_option=true
        shift
        ;;
      *)
        echo -e "${ERROR} Invalid argument specifier '$1'! Please refer to usage!"
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

# Check that either -n or -l is specified, but not both
if [[ "$n_option" = true && "$l_option" = true ]]; then
    echo -e "$ERROR -n (--process-name) and -l (--pid-list) are mutually exclusive options."
    usage
    exit 1
fi

# Check that either -n or -pp is specified, but not both
if [[ "$n_option" = true && "$pp_option" = true ]]; then
    echo -e "$ERROR -n (--process-name) and -pp (--parent-pid) are mutually exclusive options."
    usage
    exit 1
fi

# Check that either -l or -pp is specified, but not both
if [[ "$n_option" = true && "$pp_option" = true ]]; then
    echo -e "$ERROR -l (--pid-list) and -pp (--parent-pid) are mutually exclusive options."
    usage
    exit 1
fi

# Check that 1 of the main option is specified
if [[ "$n_option" = false && "$l_option" = false && "$pp_option" = false ]]; then
    echo -e "$ERROR Either -n (--process-name), -l (--pid-list) or -pp (--parent-pid) must be specified."
    usage
    exit 1
fi

# Check that -pp is always paired with -t
if [[ "$pp_option" = false && "$t_option" = true ]]; then
    echo -e "$ERROR -t (--tid-list) must be used with -p (--parent-pid)."
    usage
    exit 1
fi
if [[ "$pp_option" = true && "$t_option" = false ]]; then
    echo -e "$ERROR -p (--parent-pid) must be used with -t (--tid-list)."
    echo -e "$INFO Available Thread TIDs: "$(ls /proc/$PARENT_PID/task -1 | tail -n +2 | paste -sd " ")
    usage
    exit 1
fi

# Check that -s is specified
if [[ "$s_option" = false ]]; then
    echo -e "$ERROR -s (--script) must be specified!"
    usage
    exit 1
fi

# Check if -w is specified, it must be with -n only
if [[ "$w_option" = true && "$l_option" = true ]]; then
  echo -e "$ERROR -w (--wait) cannot be used with -l (--pid-list)"
  usage
  exit 1
fi
if [[ "$w_option" = true && "$pp_option" = true ]]; then
  echo -e "$ERROR -w (--wait) cannot be used with -pp (--parent-pid)"
  usage
  exit 1
fi

# Check if -d is specified
if [[ "$d_option" = true ]]; then
  if ! is_numeric $DELAY_TIME && ! is_float $DELAY_TIME; then
    echo -e "$ERROR -d (--delay) expected an integer or float but got something else instead!"
    usage
    exit 1
  fi
fi

# Globals
GDB_PATH="/usr/bin/gdb"
CURR_DIR=$(dirname "$(realpath "$0")")
CURR_DATETIME=`date +"%d-%m-%YT%H-%M-%S"`
LOGS_DIR=$CURR_DIR/logs/$CURR_DATETIME
DATABASE_DIR=$CURR_DIR/database
reference_file="$DATABASE_DIR/$CURR_DATETIME/sessions.txt"
gdb_pids=()
target_process_pids=()
target_process_names=()
target_parent_process_pid=0
target_thread_tids=()

if [[ "$n_option" = true && "$l_option" = false && "$w_option" = false ]]; then
  target_process_pids=($(pidof $PROCESS_NAME))
elif [[ "$n_option" = true && "$l_option" = false && "$w_option" = true ]]; then
  echo -e "$INFO Waiting for $PROCESS_NAME to spawn..."
  while true
  do
    target_process_pids=($(pidof $PROCESS_NAME))
    if [[ -n "$target_process_pids" ]]; then
      echo -e "$INFO Found $PROCESS_NAME:" "${target_process_pids[@]}"
      break
    fi
  done
elif [[ "$n_option" = false && "$l_option" = true ]]; then
  target_process_pids=("${PID_LIST[@]}")
elif [[ "$pp_option" = true && "$t_option" = true ]]; then
  target_parent_process_pid=$PARENT_PID
  target_thread_tids=("${TID_LIST[@]}")
fi


# Sanity check for all user arguments
check_user_args

# Setting up environment
mkdir -p $LOGS_DIR/gdb_output
mkdir -p $DATABASE_DIR/$CURR_DATETIME

# Entry point
run_multiple_gdb_instances
