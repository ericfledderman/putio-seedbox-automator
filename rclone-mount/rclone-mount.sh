#!/usr/bin/env bash

## =============================================================================
#   title       rclone-mount
#   description Mount an rclone remote to a specified directory.
#   git url     https://github.com/ericfledderman/putio-seedbox-automator/blob/master/rclone-mount
#   author      Eric Fledderman
#   version     0.1.0
#   usage       bash rclone-mount.sh
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
#   To automate the mounting process, copy the rclone-mount.service file to the
#   /etc/systemd/system directory, then run the following two commands:
#
#   systemctl start rclone-mount.service
#   systemctl enable rclone-mount.service




## -----------------------------------------------------------------------------
#   Global Variables
## -----------------------------------------------------------------------------

APP_NAME=$(basename "$0" .sh)
APP_VERSION=0.1.0


## -----------------------------------------------------------------------------
#   Styling
## -----------------------------------------------------------------------------

# Set font colors
BLUE="\033[1;34m"
GRAY="\033[1;30m"
GRAYL="\033[0;37m"
GREEN="\033[0;32m"
RED="\033[0;31m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Set font styles
BOLD="\e[1m"
UNDERLINE="\e[4m"
NS="\e[0m"


## -----------------------------------------------------------------------------
#   Functions
## -----------------------------------------------------------------------------

###
 #  Verifies that all the required config values have been set (at the top of
 #  this script).
 ##
config_check () {
  # CACHE_DIR check
  if [ -z ${CACHE_DIR} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'CACHE_DIR' received.\n" 2>&1 | tee -a .log
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n" 2>&1 | tee -a .log
    exit 1
  fi

  # CONFIG_DIR check
  if [ -z ${CONFIG_DIR} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'CONFIG_DIR' received.\n" 2>&1 | tee -a .log
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n" 2>&1 | tee -a .log
    exit 1
  fi

  # MOUNT_DIR check
  if [ -z ${MOUNT_DIR} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'MOUNT_DIR' received.\n" 2>&1 | tee -a .log
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n" 2>&1 | tee -a .log
    exit 1
  fi

  # REMOTE check
  if [ -z ${REMOTE} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'REMOTE' received.\n" 2>&1 | tee -a .log
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n" 2>&1 | tee -a .log
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
    printf "$(timestamp) ${GRAY}[${ORANGE}ALERT${GRAY}]${NC} Log file size has exceeded 1GB:\n" 2>&1 | tee -a .log
    printf "$(timestamp)   - Trimming...                                   " 2>&1 | tee -a .log

    # Continue trimming until log file size is smaller than 0.5GB
    while [ $(du - .log | cut -f 1) -ge 529288 ]
    do
      # Trim line by line
      sec -i "1d" .log
    done
    printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n" 2>&1 | tee -a .log
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
  printf "${APP_NAME} [cache_dir] [config_dir] [mount_dir] [remote]

Mount an rclone remote to a specified directory.

 Required:
  --cache_dir     VALUE    Directory where cache will be stores
  --config_dir    VALUE    Location of the rclone.conf file
  --mount_dir     VALUE    Mount location
  --remote        VALUE    Rclone remote to be mounted

 Options:
  --help                   Display this help and exit
  --version                Output version information and exit
\n"
}

## -----------------------------------------------------------------------------
#   Application
## -----------------------------------------------------------------------------

function rclone_mount () {
  # "Splash Screen"
  printf "$(timestamp) ${BOLD}${UNDERLINE}Initiating rclone-mount:${NS}\n\n" 2>&1 | tee -a .log

  # Check that all config values have been declared
  config_check

  # Check that the log file hasn't exceeded 1GB
  log_check

  # Check that fuse has been initialized
  if [ ! -d /dev/fuse ]
  then
    # Feedback to user
    printf "$(timestamp) ${GRAY}[${ORANGE}ALERT${GRAY}]${NC} Fuse has not been initialized..." 2>&1 | tee -a .log
    printf "$(timestamp)   - Initializing                                  " 2>&1 | tee -a .log

    # Prepare VM for fuse mounting
    mknod -m 666 /dev/fuse c 10 229

    # Feedback to user
    printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n\n" 2>&1 | tee -a .log
  fi

  # Feedback to user
  printf "$(timestamp) Preparing to mount..." 2>&1 | tee -a .log

  # Mounting remote
  /usr/bin/rclone mount \
    --rc \
    --umask 022 \
    --allow-non-empty \
    --allow-other \
    --fuse-flag sync_read \
    --tpslimit 10 \
    --tpslimit-burst 10 \
    --dir-cache-time=160h \
    --buffer-size=64M \
    --attr-timeout=1s \
    --vfs-read-chunk-size=2M \
    --vfs-read-chunk-size-limit=2G \
    --vfs-cache-max-age=5m \
    --vfs-cache-mode=writes \
    --cache-dir ${CACHE_DIR} \
    --config ${CONFIG_DIR}/rclone.conf \
    ${REMOTE} ${MOUNT_DIR}

  # Feedback to user
  printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n" 2>&1 | tee -a .log
  printf "$(timestamp) Finished. Now exitting...\n" 2>&1 | tee -a .log
  exit 1
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
    --cache_dir)
      shift
      CACHE_DIR=${1}
      ;;
    --config_dir)
      shift
      CONFIG_DIR=${1}
      ;;
    --mount_dir)
      shift
      MOUNT_DIR=${1}
      ;;
    --remote)
      shift
      REMOTE=${1}
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
rclone_mount
