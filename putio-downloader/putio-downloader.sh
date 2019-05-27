#!/usr/bin/env bash

## =============================================================================
#   title       putio-downloader
#   description Downloads files from Put.io account into specifiec directory.
#   git url     https://github.com/ericfledderman/putio-seedbox-automator/blob/master/putio-downloader
#   author      Eric Fledderman
#   version     0.1.0
#   usage       bash putio-downloader.sh
#   notes       Part of the 'putio-seedbox-automator' package.
#
#   changelog
# ------------------------------------------------------------------------------
#   Date          Version    Notes
# ------------------------------------------------------------------------------
#   2019-05-27    v0.1.0     Initial code
## =============================================================================




## *****************************************************************************
#   ALERT!!!
## *****************************************************************************
#   Remember to add the following to entry to crontab, replacing filenames and
#   paths accordingly
#
# */15 * * * * pgrep putio-downloader.sh || /bin/bash /path/to/putio-downloader/putio-downloader.sh [config_dir] [source_path] [dest_path] >> /path/to/putio-downloader/.log




## -----------------------------------------------------------------------------
#   Global Variables
## -----------------------------------------------------------------------------

APP_NAME=$(basename "$0" .sh)
APP_VERSION=0.1.0


## -----------------------------------------------------------------------------
#  Styling
## -----------------------------------------------------------------------------

# Colors
BLUE="\033[1;34m"
GRAY="\033[1;30m"
GRAYL="\033[0;37m"
GREEN="\033[0;32m"
RED="\033[0;31m"
ORANGE="\033[0;33m"
NC="\033[0m"

# Font styles
BOLD="\e[1m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
NS="\e[0m"

## -----------------------------------------------------------------------------
#  Functions
## -----------------------------------------------------------------------------

###
 #  Verifies that all the required config values have been set (at the top of
 #  this script).
 ##
config_check () {
  # CONFIG_DIR check
  if [ -z ${CONFIG_DIR} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'CONFIG_DIR' received.\n"
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n"
    exit 1
  fi

  # SOURCE_PATH check
  if [ -z ${SOURCE_PATH} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'SOURCE_PATH' received.\n"
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n"
    exit 1
  fi

  # DEST_PATH check
  if [ -z ${DEST_PATH} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'DEST_PATH' received.\n"
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n"
    exit 1
  fi
}

###
 #  Evaluates the log file size. If it exceeds 1GB, function will trim line by
 #  line until the log file size is smaller than 0.5GB (529,288 bytes)
 ##
log_check () {
  # Check if log file size exceeds 1GB
  if [ $(du -k .log | cut -f 1) -ge 1048576 ]
  then
    # Feedback to user
    printf "$(timestamp) ${GRAY}[${ORANGE}ALERT${GRAY}]${NC} Log file size has exceeded 1GB
:\n" 2>&1 | tee -a .log
    printf "$(timestamp)   - Trimming...                                   "

    # Continue trimming until log file size is smaller than 0.5GB
    while [ $(du - .log | cut -f 1) -ge 529288 ]
    do
      # Trim line by line
      sec -i "1d" .log
    done
    printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n"
  fi
}

###
 #  Creates a timestamp to be used in printed statements
 ##
timestamp () {
  date +"${GRAY}[${GRAYL}%Y-%m-%d %T${GRAY}]${NC}"
}

###
 #  Prints usage information
 ##
usage () {
  printf "${APP_NAME} [config_dir] [source_path] [dest_path]

Downloads files from Put.io account into specifiec directory.

 Required:
  --config_dir     VALUE    Location of the rclone.conf file
  --source_path    VALUE    Path to source files from
  --dest_path      VALUE    Path where files should be downloaded to

 Options:
  --help                    Display this help and exit
  --version                 Output version information and exit
\n"
}


## -----------------------------------------------------------------------------
#  Application
## -----------------------------------------------------------------------------

function putio_downloader () {
  # Check if script is already running
  printf "$(timestamp) ${BOLD}${UNDERLINE}Initiating reclone-move service:${NS}\n\n"

  # Check that all config values have been declared
  config_check

  # Check that the log file hasn't exceeded 1GB
  log_check  

  # Perform diff against source and destination
  response=$(rclone check \
    ${SOURCE_PATH} ${DEST_PATH} \
    --quiet \
    --config="${CONFIG_DIR}/rclone.conf")

  if [[ $response == *"0 differences found"* ]]
  then
    # No differences found
    # Show active feedback
    printf "$(timestamp) ${ORANGE}No new files found...${NC}\n"
  else
    printf "$(timestamp) ${GREEN}New files found!${NC}\n"

    # Move new files from source to destination
    printf "$(timestamp)   - Downloading new file(s)...                    "
    rclone move \
      ${SOURCE_PATH} ${DEST_PATH} \
      --progress \
      --config="${CONFIG_DIR}/rclone.conf"
    printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n"

    printf "$(timestamp)   - Cleaning up...                                "
    rclone rmdirs \
      ${SOURCE_PATH}/Movies \
      --leave-root \
      --config="${CONFIG_DIR}/rclone.conf"

    rclone rmdirs \
      ${SOURCE_PATH}/Television \
      --leave-root \
      --config="${CONFIG_DIR}/rclone.conf"
    printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n"
  fi
}


## -----------------------------------------------------------------------------
#   Utilities
## -----------------------------------------------------------------------------

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
# [[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    --help)
      usage >&2;
      exit 1
      ;;
    --version)
      printf "$(basename $0) ${version}\n"
      exit 1
      ;;
    --config_dir)
      shift
      CONFIG_DIR=${1}
      ;;
    --source_path)
      shift
      SOURCE_PATH=${1}
      ;;
    --dest_path)
      shift
      DEST_PATH=${1}
      ;;
    *)
      printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} Invalid option: '${1}'.\n"
      printf "$(timestamp) ${YELLOW}Exitting...${NC}\n"
      exit 1
      ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

# Run the script
putio_downloader
