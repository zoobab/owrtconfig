#!/bin/sh

ME="owrtconfig.sh"
VER="0.03"
IP="192.168.1.1"
SKIP_LINE_COUNT=0

_error() {
	echo "$ME: $*"
	exit 1
}

_usage() {
  cat <<__END_OF_USAGE
$ME v$VER

Usage: $ME OPTIONS -H HOSTS -C COMMANDS

  -P PROTOCOL   protocol used to connect on each node (ssh or telnet, default: ssh)
  -H HOSTS      file containing hosts list (hwaddr,param1,param2...param9))
  -C COMMANDS   file containing commands to be run on each host
  -a ADDRESS    default IP address of each host (default: 192.168.1.1)
  -n LINES      lines to skip from remote output (default: 0)
  -s            use sudo (when you're not running this script as root)

  -h            display usage information (this help screen)
  -v            display version information

__END_OF_USAGE
}

_version() {
  cat <<__END_OF_VERSION
$ME v$VER
__END_OF_VERSION
}

_parse_args() {
	while [ -n "$1" ]; do
		case $1 in
		  -P|--protocol)
			shift
			PROTOCOL="$1"
			;;
		  -H|--hosts)
			shift
			HOSTS_F="$1"
			;;
		  -C|--commands)
			shift
			COMMANDS_F="$1"
			;;
		  -a)
			shift
			IP="$1"
			;;
		  -n)
			shift
			SKIP_LINE_COUNT="$1"
			;;
		  -s|--sudo)
			SUDO_FUNC="sudo"
			;;
		  -h|--help)
			_usage
			exit 0
			;;
		  -v|--version)
			_version
			exit 0
			;;
		  *)
			_error "unexpected argument"
			;;
		esac
		shift
	done
}

_parse_args $*

[ -n "$PROTOCOL" ] \
	|| _error "missing '-P PROTOCOL' argument"
[ -n "$HOSTS_F" ] \
	|| _error "missing '-H HOSTS' argument"
[ -n "$COMMANDS_F" ] \
	|| _error "missing '-C COMMANDS' argument"
[ -f "$HOSTS_F" ] \
	|| _error "error accessing HOSTS file '$HOSTS_F'"
[ -f "$COMMANDS_F" ] \
	|| _error "error accessing COMMANDS file '$COMMANDS_F'"

_ssh( )
{
	ssh -T -o "StrictHostKeyChecking no" root@"$IP" 2>&1
}

_telnet( )
{
	nc -i 1 -t "$IP" 23 2>&1
}

case $PROTOCOL in
  ssh)
	PROTOCOL_FUNC="_ssh"
	;;
  telnet)
	PROTOCOL_FUNC="_telnet"
	;;
esac

echo "1. checking sudo..."
sudo true || exit 1

echo "2. looping over nodes..."
IFS=","
cat $HOSTS_F | grep -v '^#' |  sed -e 's/ *, */,/g' -e's/\//###/g' -e 's/\&\&/####/g'  | while read mac param1 param2 param3 param4 param5 param6 param7 param8 param9; do
  echo -n "-- mac: $mac -- " 1>&2
  sudo arp -s $IP $mac >/dev/null
  ping -c 1 -q -r -t 1 $IP >/dev/null
  if [ $? -eq 0 ]; then
    echo "alive! ---" 1>&2
    echo "[$mac] [$param1] [$param2] [$param3] [$param4] [$param5] [$param6] [$param7] [$param8] [$param9]"
    cat $COMMANDS_F \
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
        | $PROTOCOL_FUNC | tail -n +$SKIP_LINE_COUNT
  else
    echo "not found! ---" 1>&2
  fi
  sudo arp -d $IP >/dev/null
done
echo "3. done!"
