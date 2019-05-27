#!/usr/bin/env bash

## =============================================================================
#   title       blackhole-uploader
#   description Uploads .torrent and .magnet files from a blackhole directory
#               to Put.io for downloading.
#   git url     https://github.com/ericfledderman/putio-seedbox-automator/blob/master/blackhole-uploader
#   author      Eric Fledderman (ericfledderman@me.com)
#   version     0.1.0
#   usage       bash blackhole-uploader.sh
#   notes(1)    Copy (and rename) this file into the directory of your choice.
#   notes(2)    Part of the 'putio-seedbox-automator' package.
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
# */15 * * * * pgrep blackhole-uploader.sh || /bin/bash /path/to/blackhole-uploader/blackhole-uploader.sh [-b blackhole directory] [-o oauth key] [-p put.io directory] >> /path/to/blackhole-uploader/.blackhole.log




## -----------------------------------------------------------------------------
#   Global Variables
## -----------------------------------------------------------------------------

APP_NAME=$(basename "$0" .sh)
APP_VERSION=0.1.0


## -----------------------------------------------------------------------------
#   Styling
## -----------------------------------------------------------------------------

# Colors
BLUE="\033[1;34m"
GRAY="\033[1;30m"
GRAYL="\033[0;37m"
GREEN="\033[0;32m"
RED="\033[0;31m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Font styles
BOLD="\e[1m"
UNDERLINE="\e[4m"
NS="\e[0m"


## -----------------------------------------------------------------------------
#   Functions
## -----------------------------------------------------------------------------

###
 #  Verifies that all the required config values have been set.
 ##
config_check () {
  # BLACKHOLE_DIR check
  if [ -z ${BLACKHOLE_DIR} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'BLACKHOLE_DIR' received.\n"
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n"
    exit 1
  fi

  # OAUTH_TOKEN check
  if [ -z ${OAUTH_TOKEN} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'OAUTH_TOKEN' received.\n"
    printf "$(timestamp) ${YELLOW}Exitting...${NC}\n"
    exit 1
  fi

  # PUTIO_DIR check
  if [ -z ${PUTIO_DIR} ]
  then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} No 'PUTIO_DIR' received.\n"
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
  if [ $(du -k ".${APP_NAME}.log" | cut -f 1) -ge 1048576 ]
  then
    # Feedback to user
    printf "$(timestamp) ${GRAY}[${ORANGE}ALERT${GRAY}]${NC} Log file size has exceeded 1GB:\n"
    printf "$(timestamp)   - Trimming...                                   "
    # Continue trimming until log file size is smaller than 0.5GB
    while [ $(du -k ".${APP_NAME}.log" | cut -f 1) -ge 529288 ]
    do
      # Trim line by line
      sec -i "1d" ".${APPNAME}.log"
    done
    printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n\n"
  fi
}

###
 #  Evaluate the filetype. Valid filetypes will be uploaded to Put.io and then
 #  purged. Invalid filetypes will simply be purged.
 ##
process_file () {
  # Feedback to user
  printf "$(timestamp) Processing: ${BLUE}${file:0:25}${NC}:\n"

  # Upload to Put.io
  printf "$(timestamp)   - Uploading to Put.io...                        "

  ## Post file to API endpoint
  response=$(curl -sX POST \
    https://upload.put.io/v2/files/upload \
    -H "Accept: */*" \
    -H "Authorization: Bearer ${OAUTH_TOKEN}" \
    -H "Cache-Control: no-cache" \
    -H "Connection: keep-alive" \
    -H "Content-Type: multipart/form-data" \
    -H "Host: upload.put.io" \
    -F file=@"${BLACKHOLE_DIR}/${file}" \
    -F parent_id=${PUTIO_DIR} | \
    jq ".")

  ## Get response status
  status=$(echo ${response} | jq ".status" | tr -d "\"")

  ## Validate response status
  case "${status}" in
    "OK")
      ## Feedback to user
      printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n"

      ## Declare filetype as valid
      VALID=true

      ## Set file to be purged
      purge_file ${file} ${VALID}
      ;;
    "ERROR")
      ## Determine error type
      error_type=$(echo ${response} | jq ".error_type" | tr -d "\"")

      ## Evaluate error type
      if [ "${error_type}" = "Alreadyadded" ]
      then
        ## Feedback to user
        printf "${GRAY}[${ORANGE}ALERT${GRAY}]${NC} Already added.\n"

        ## Declare filetype as valid
        VALID=true

        ## Set file to be purged
        purge_file ${file} ${VALID}
      else
        ## Feedback to user
        printf "${GRAY}[${RED}ERROR${GRAY}]${NC} An uknown error occurred. Skipping file purge.\n"
      fi
      ;;
    *)
      ## Feedback to user
      printf "${GRAY}[${RED}ERROR${GRAY}]${NC} Server gave an unknown response. Skipping file purge.\n"
      ;;
  esac
}

###
 #  Removes files from the local storage. To be used after filetype has already
 #  been evaluated.
 ##
purge_file () {
  # Alert user of invalid file type
  if [ ! ${VALID} ]
  then
    printf "$(timestamp) ${ORANGE}Invalid file type${NC}: ${BLUE}${file:0:25}${NC}\n"
  fi

  # Purge file
  printf "$(timestamp)   - Purging from blackhole directory...           "
  rm -rf "${BLACKHOLE_DIR}/${file}"
  printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n"
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
  printf "${APP_NAME} [blackhole directory] [oauth key] [put.io directory]

Uploads .torrent and .magnet files from a blackhole directory to Put.io for downloading.

 Required:
  --blackhole_dir     VALUE    Directory where torrent files are located
  --oauth_key         VALUE    OAuth Key generated from your Put.io account
  --putio_dir         VALUE    Put.io directory where files should be downloaded to

 Options:
  --help                       Display this help and exit
  --version                    Output version information and exit
\n"
}


## -----------------------------------------------------------------------------
#   Application
## -----------------------------------------------------------------------------

function blackhole_uploader () {
  # "Splash Screen"
  printf "$(timestamp) ${BOLD}${UNDERLINE}Initiating ${APP_NAME}:${NS}\n\n"

  # Check that all config values have been declared
  config_check ${APP_NAME}

  # Check that the log file hasn't exceeded 1GB
  log_check

  # Verify that BLACKHOLE_DIR has contents
  if [[ $(ls -A ${BLACKHOLE_DIR}) ]]
  then
    # Assign contents to variable
    files=($(ls -1 $BLACKHOLE_DIR))

    # Feedback to user
    printf "$(timestamp) ${GREEN}New requests found!${NC}\n"

    # Iterate over contents
    cd ${BLACKHOLE_DIR}
    for file in *
    do
      # Set filetype to invalid (by default)
      VALID=false

      # Determine how to process file
      case "${file}" in
        # Process valid filetypes
        *.torrent|*.magnet)
          process_file ${file}
          ;;
        # Purge invalid filetypes
        *)
          purge_file ${file} ${VALID}
          ;;
      esac
    done
  else
    # Feedback to user
    printf "$(timestamp) ${YELLOW}No new requests found...${NC}\n\n"
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
    --blackhole_dir)
      shift
      BLACKHOLE_DIR=${1}
      ;;
    --oauth_token)
      shift
      OAUTH_TOKEN=${1}
      ;;
    --putio_dir)
      shift
      PUTIO_DIR=${1}
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
blackhole_uploader
