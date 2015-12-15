#!/usr/bin/expect --

set RUN_IN_TIME 0
set RUN_IN_CYCLE 0
set IS_DEBUG 0

incr RUN_IN_TIME	

puts $RUN_IN_TIME
puts $RUN_IN_CYCLE
puts $IS_DEBUG

set count 0
while {[lindex $argv $count] > 0} {
    switch -regexp -- [lindex $argv $count] {
	(-h|--help){
			puts [lindex $argv $count]
            puts "$package - Pico Power Cycle Test for Chassy"
            puts " "
            puts "$package [options] application [arguments]"
            puts " "
            puts "options:"
            puts "-t        How long the script will be run. the default value will be for"
			puts "-c        Specify an how many cycles to run (higher priority then time)"
            puts "-d        Display debug information"
			}
	}
   	puts [lindex $argv $count]
	incr count
}



