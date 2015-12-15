#!/usr/bin/expect --

package require cmdline
proc displayDebug {content} {
	puts $content
}

set startTime [clock seconds]

set parameters {
    {time.arg 4   "Number of hour to run, default is 4"}
	{cycle.arg 0   "Number of cycle to run, default is 0(use time). Higher priority than time"}
    {debug "Turn on debugging, default=off"}
}

set usage "Chassy power cycle test script"
if {[catch {array set options [cmdline::getoptions ::argv $parameters $usage]}]} {
    puts [cmdline::usage $parameters $usage]
} else {
    parray options
}

array set listSerialNumber {}
#Init array storage
for {set i 1} {$i < 16} {incr i 1} {
	set listSerialNumber($i) $i
} 
parray listSerialNumber
sleep 2
set endTime [expr {[clock seconds] - $startTime}]
displayDebug $endTime


#parray options
#
#puts "There are $argc arguments to this script"
#puts "The name of this script is $argv0"
#if {$argc > 0} {puts "The other arguments are: $argv" }
#puts "You have these environment variables set:"


