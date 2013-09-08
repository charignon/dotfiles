#!/usr/bin/env bash

ED="emacs"
EC="emacsclient"
OPTS=""
SF="$HOME/.emacs.d/server/server"
PORT="1"
HN=$(hostname -f)

# check for emacsclient path, fallback to home directory
hash emacsclient 2>/dev/null || EC="$HOME/.local/bin/emacsclient"

# hack: if on euclid, change to a public name
[[ $HN == euclid* ]] && HN=${HN/euclid/smf}

# hack: if options contain --eval then don't parse args

if [[ $@ != *--eval* ]]; then
  # dev note: since we're using bash 'getopts' arguments MUST be before the filename provided
  while getopts ":h" opt; do
    case $opt in
      h)
        cat << EOF
usage: $0 options

This script calls emacsclient if the file $SF exists and the reverse port is open, else if it calls emacs

OPTIONS:
  -h      Show this message
  any other option will be passed to emacs or emacsclient
EOF
        exit 0
        ;;
      \?)
        OPTS="$OPTS -$OPTARG"
        ;;
    esac
  done

  # shift the optional flags provided before the filename out of the way
  shift $(( OPTIND-1 ))

  FN=$(readlink -f $1 2>/dev/null)
else
  FN=$@
fi

# if $FN is empty then this usually means a non-existent directory was provided
[[ -z $FN ]] && echo "error: check FN='$FN'" && exit 1

# if server/server file exists, then grep it for the port
[[ -r $SF ]] && PORT=$(egrep -o '127.0.0.1:([0-9]*)' $SF | sed 's/127.0.0.1://')

# check to see if port is open; apparently, ubuntu needs the -v flag
[[ -n $(nc -zv 127.0.0.1 $PORT 2>&1 | grep 'succeeded\|open') || $HOME == /Users/$USER ]] && ED="$EC -f $SF"

# build the tramp filename or local filename also
[[ $HOME != /Users/$USER ]] && FN="/$(whoami)@$HN:$FN"

$ECHO eval "$ED $OPTS $FN"
