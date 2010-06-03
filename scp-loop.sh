#!/bin/bash

ME="scp-loop.sh"
IP="192.168.1.1"
VERBOSE_O=0
HOSTS_F="./hosts.txt"

_usage() {
  cat <<__END_OF_USAGE
Usage: $ME [OPTIONS] SOURCE... TARGET

Options:
  -H,--hosts F     specify the file containing a list of hosts
                   format: MAC,PARAM1,PARAM2...PARAM9
                   default to ./hosts.txt
  -h,--help        display this help information and exit
  -v,--verbose     show what is being done

__END_OF_USAGE
}

_error() {
  echo "$ME:" $@
  exit 1
}

_message() {
  [ $VERBOSE_O -gt 0 ] && echo $@
}

argc=$#
argi=1
while [ $argi -lt $argc ]; do
  case $1 in
    -H|--hosts)
      shift
      argi=$(($argi + 1))
      HOSTS_F=$1
      ;;
    -h|--help)
      _usage
      exit 0
      ;;
    -v|--verbose)
      VERBOSE_O=$(($VERBOSE_O + 1))
      ;;
    *)
      SOURCE="${SOURCE}${SOURCE:+ }$1"
      ;;
  esac
  shift
  argi=$(($argi + 1))
done
TARGET=$1

_sudo() {
	sudo $*
}

_ping() {
	ping -c 1 -q -r -t 1 "$IP" >/dev/null 2>&1
	return $?
}

_scp() {
	scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" $SOURCE root@"$IP":$TARGET 2>&1
}

[ -n "$HOSTS_F" -a -n "$SOURCE" -a -n "$TARGET" ] || {
  _usage
  exit 1
}
[ -r "$HOSTS_F" ] || _error "error accessing HOSTS file '$HOSTS'"

_message "1. checking sudo..."
_sudo true || exit 1

_message "2. looping over nodes..."
IFS_OLD="$IFS"
IFS_NEW=","
IFS="$IFS_NEW"
cat $HOSTS_F | grep -v '^#' | while read mac p1 p2 p3 p4 p5 p6 p7 p8 p9; do
  IFS="$IFS_OLD"
  _sudo arp -s $IP $mac >/dev/null
  _ping
  if [ $? -eq 0 ]; then
    _message "-- mac: $mac -- alive! --" 1>&2
    _scp 
  else
    _message "-- mac: $mac -- not found! --" 1>&2
  fi
  _sudo arp -d $IP >/dev/null
  IFS="$IFS_NEW"
done
IFS="$IFS_OLD"
_message "3. done!"
