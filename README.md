# checksig.sh
Quick and dirty DNSSEC signature expiration check for Nagios.

Check the remaining time before an SOA RRSIG expires, and respond to
dangerous situations with appropriately-flappy arms.

Syntax:
  checksig.sh server zone warn-threshold crit-threshold

Specify the thresholds in integer numbers of seconds, or echo "minutes
with the suffix 'm', hours with 'h' or days with 'd'.

Return codes are zero ("ok"), 1 ("warning"), 2 ("critical") or 99
("weirdness"). This ought to be suitable for use as a nagios plugin.
You need GNU awk installed (as "gawk", unless you make adjustments)
in order to parse the expiration date in the target RRSIG.

Example:
  checksig.sh 8.8.8.8 hopcount.ca. 5d 1d

Written by Joe Abley in half an hour during a KENIC/NSRC workshop in
Nairobi in March 2018 while Phil Regnauld scrambled to throw a nagios demo
together.  I hope you enjoy this documentation. It's all you're getting.

jabley@nsrc.org
regnauld@nsrc.org
