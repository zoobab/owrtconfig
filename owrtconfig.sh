#!/bin/bash

ME="owrtconfig.sh"
VER="0.02"
IP="192.168.1.1"
SKIP_LINE_COUNT=11

_usage() {
  cat <<__END_OF_USAGE
$ME v$VER

Usage: $ME -PROTOCOL HOSTS COMMANDS

  PROTOCOL   -ssh, -telnet, -scp
  HOSTS      file containing hosts list (hwaddr,param1,param2...param9))
  COMMANDS   file containing commands to be run on each host

Example: $ME -telnet nodes.csv commands.sh

__END_OF_USAGE
}

PROTOCOL=$1
HOSTS=$2
COMMANDS=$3
[ -n "$HOSTS" -a -n "$COMMANDS" ] || {
  _usage
  exit 1
}
[ -f "$HOSTS" ] || {
  echo "$ME: error accessing HOSTS file '$HOSTS'"
  exit 1
}
[ -f "$COMMANDS" ] || {
  echo "$ME: error accessing COMMANDS file '$COMMANDS'"
  exit 1
}

echo "1. checking sudo..."
sudo true || exit 1

echo "2. looping over nodes..."
IFS=","
cat $HOSTS | grep -v '^#' |  sed -e 's/ *, */,/g' -e's/\//###/g' -e 's/\&\&/####/g'  | while read mac param1 param2 param3 param4 param5 param6 param7 param8 param9; do
  echo -n "-- mac: $mac -- " 1>&2
  sudo arp -s $IP $mac >/dev/null
  ping -c 1 -q -r -t 1 $IP >/dev/null
  if [ $? -eq 0 ]; then
    echo "alive! ---" 1>&2
    echo "[$mac] [$param1] [$param2] [$param3] [$param4] [$param5] [$param6] [$param7] [$param8] [$param9]"
    cat $COMMANDS \
	| sed	-e "s/@MAC@/$mac/g" \
		-e "s/@PARAM1@/$param1/g" \
		-e "s/@PARAM2@/$param2/g" \
		-e "s/@PARAM3@/$param3/g" \
		-e "s/@PARAM4@/$param4/g" \
		-e "s/@PARAM5@/$param5/g" \
		-e "s/@PARAM6@/$param6/g" \
		-e "s/@PARAM7@/$param7/g" \
		-e "s/@PARAM8@/$param8/g" \
		-e "s/@PARAM9@/$param9/g" \
		-e "s/####/\&\&/g" \
		-e "s/###/\//g" \
        | nc "$IP" 23 2>&1 \
	| tail -n +$SKIP_LINE_COUNT
  else
    echo "not found! ---" 1>&2
  fi
  sudo arp -d $IP >/dev/null
done
echo "3. done!"
