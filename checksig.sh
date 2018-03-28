#!/bin/sh
#
# usage: checksig.sh zone warn-seconds crit-seconds
#

if [ $# -ne 4 ]
then
  cat <<EOF >&2
Check the remaining time before an SOA RRSIG expires, and respond to
dangerous situations with appropriately-flappy arms.

Syntax:
  $(basename $0) server zone warn-threshold crit-threshold

Specify the thresholds in integer numbers of seconds, or echo "minutes
with the suffix 'm', hours with 'h' or days with 'd'.

Return codes are zero ("ok"), 1 ("warning"), 2 ("critical") or 3
("weirdness"). This ought to be suitable for use as a nagios plugin.
You need GNU awk installed (as "gawk", unless you make adjustments)
in order to parse the expiration date in the target RRSIG.

Example:
  $(basename $0) 8.8.8.8 hopcount.ca. 5d 1d

Written by Joe Abley in half an hour during a KENIC/NSRC workshop in
Nairobi in March 2018 while Phil Regnauld scrambled to throw a nagios demo
together.  I hope you enjoy this documentation. It's all you're getting.

jabley@nsrc.org
regnauld@nsrc.org
EOF
  exit 3
fi

timespec () {
  val=$(echo $1 | tr -d dhm)

  case $1 in
    *m)
      echo "$((${val} * 60))"
      ;;
    *h)
      echo "$((${val} * 60 * 60))"
      ;;
    *d)
      echo "$((${val} * 60 * 60 * 24))"
      ;;
    *)
      echo $1
      ;;
  esac
}

server=$1
zone=$(timespec $2)
warn=$(timespec $3)
crit=$(timespec $4)

if [ ${warn} -lt ${crit} ]
then
  echo "The warning threshold (${warn} seconds) is less than the critical threshold (${crit} seconds), which is weird." >&1
  exit 3
fi

remaining=$(dig @${server} ${zone} SOA +dnssec +noall +answer \
    | gawk '
  /RRSIG/ {
    expiration = $9;
    remaining = mktime(substr(expiration, 1, 4) " " \
      substr(expiration, 5, 2) " " \
      substr(expiration, 7, 2) " " \
      substr(expiration, 9, 2) " " \
      substr(expiration, 11, 2) " " \
      substr(expiration, 13, 2)) - systime();

    print remaining;

    exit;
  }')

if [ -z "${remaining}" ]
then
  echo "Could not find the signature expiration for zone ${zone}"
  exit 3
fi

if [ ${remaining} -lt 0 ]
then
  echo "Signatures in zone ${zone} expired $((-1 * ${remaining})) seconds ago, as observed on server ${server}"
  exit 2
fi

if [ ${remaining} -lt ${crit} ]
then
  echo "Remaining signature validity for zone ${zone} is ${remaining} seconds, less than the critical threshold of ${crit} seconds, as observed on server ${server}"
  exit 2
fi

if [ ${remaining} -lt ${warn} ]
then
  echo "Remaining signature validity for zone ${zone} is ${remaining} seconds, less than the warning threshold of ${warn} seconds, as observed on server ${server}"
  exit 1
fi

echo "Remaining signature validity for zone ${zone} is ${remaining} seconds, which is ok (less than the warning threshold of ${warn} seconds), as observed on server ${server}"

exit 0
