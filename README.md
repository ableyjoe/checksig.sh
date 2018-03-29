# checksig.sh

Quick and dirty DNSSEC signature expiration check for Nagios.

Check the remaining time before an SOA RRSIG expires, and respond
to dangerous situations with appropriately-flappy arms. If there
are multiple RRSIGs, react to the most dangerously-expirey-looking
one.


## Syntax

~~~
checksig.sh server zone warn-threshold crit-threshold
~~~

... where server can be one of the authoritative NSes for the specified
zone, or a resolver.

Specify the thresholds in integer numbers of seconds, or minutes
with the suffix 'm', hours with 'h' or days with 'd'.

Return codes are zero ("ok"), 1 ("warning"), 2 ("critical") or 3
("unknown"). This ought to be suitable for use as a nagios plugin.
You need GNU awk installed (as "gawk", unless you make adjustments)
in order to parse the expiration date in the target RRSIG.

## Example

~~~
  checksig.sh 8.8.8.8 hopcount.ca. 5d 1d
~~~

## Nagios integration

### Typical check command

~~~
define command {
  command_name    checksig
  command_line    /usr/lib/nagios/plugins/checksig.sh $ARG1$ $ARG2$ $ARG3$ $ARG4$
}
~~~

Note: since the target of the check is zone contents and not service status on
a specific host, it didn't seem useful to pass $HOSTADDRESS$ as a parameter
to the check. This lets the user pass any server to query as the first
parameter.

### Typical check definition

~~~
define service {
        use                             generic-service
        host_name                       name.of.primary.server.hosting.zone
        service_description             DNSSEC status for hopcount.ca
        check_command                   checksig!8.8.8.8!hopcount.ca!15d!7d
}
~~~

## Improvements

Yes please.

* Would be nice with the ability to do a synthetic check across a number of
  zones, or of a given zone across multiple servers (all authoritative servers
  for example).

* Ability to query a given set of records (canary RRs and/or combination
  of multiple records).

* Ability to define aggregate result method (critical on any failure, or
  average).

Written by Joe Abley in half an hour during a KENIC/NSRC workshop in
Nairobi in March 2018 while Phil Regnauld scrambled to throw a nagios demo
together, while cursing at the fact that other dnssec check plugins had
either disappeared, wouldn't compile, or wouldn't work with recent versions
of Ruby. I hope you enjoy this documentation. It's all you're getting.

jabley@nsrc.org, regnauld@nsrc.org
