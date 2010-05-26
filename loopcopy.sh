#!/bin/bash

# TODO: check if all the binaries are in the PATH, return an error if not
# Depends: grep sudo cat echo arp ping scp arp

ME="loopcopy.sh"
IP="192.168.1.1"
SKIP_LINE_COUNT=11

_usage() {
  cat <<__END_OF_USAGE
Usage: $ME HOSTS FILES

  HOSTS   file containing hosts list (hwaddr,param1,param2...param9))
  FILES   file containing files list to be copied to each host

__END_OF_USAGE
}

HOSTS=$1
shift #shifts all commandline parameters
FILES=$* 

[ -n "$HOSTS" -a -n "$FILES" ] || {
  _usage
  exit 1
}
[ -f "$HOSTS" ] || {
  echo "$ME: error accessing HOSTS file '$HOSTS'"
  exit 1
}

for F in $FILES; do
 [ -f "$F" ] || {
  echo "$ME: error accessing FILES file '$FILES'"
  exit 1
 }
done

echo "1. checking sudo..."
sudo true || exit 1


echo "2. looping over nodes..."
cat $HOSTS | grep -v '^#' |  sed -e 's/ *, */,/g' -e's/\//###/g' -e 's/\&\&/####/g'  |  while IFS="," read mac param1 param2 param3 param4 param5 param6 param7 param8 param9; do
  echo -n "-- mac: $mac -- " 1>&2
  sudo arp -s $IP $mac >/dev/null
  ping -c 1 -q -r -t 1 $IP >/dev/null
  if [ $? -eq 0 ]; then
    echo "alive! ---" 1>&2
    echo "[$mac] [$param1] [$param2] [$param3] [$param4] [$param5] [$param6] [$param7] [$param8] [$param9]"
    scp $FILES root@192.168.1.1:/tmp
  else
    echo "not found! ---" 1>&2
  fi
  sudo arp -d $IP >/dev/null
done
echo "3. done!"
