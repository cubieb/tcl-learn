#!/usr/bin/expect --

package require cmdline

proc displayDebug {content} {
	puts $content
}

# this function to control how long will the test run
proc checkStillRunning {} {
  global options
  global startTime
  global totalRunTime
  global cycleCount

  if { $options(cycle) > 0 } {
	  if {$cycleCount > $options(cycle)} {
	    return 0
	  }
  } else {
	  set runTime [expr [clock seconds] - $startTime]
    displayDebug $runTime
    if { $runTime  > $totalRunTime } {
      return 0;
    }
  }
  incr $cycleCount
  displayDebug "Start running cycle: $cycleCount"
  return 1
}

proc updateSlotSerialNumber {spawn_id slotNumber} {
  global listSerialNumber
	if { [string length $listSerialNumber($slotNumber)] == 0} {
		displayDebug "Start Update Serial Number $slotNumber"
    send "getprop mfg.shared.picoSerialNumber\r"
    expect -re "\""
    expect -re "\""
    set serialNumber $expect_out(buffer)
    set serialNumber [ string trim  $serialNumber "\""]
    set listSerialNumber($slotNumber) $serialNumber
		displayDebug $serialNumber
	}
}


set startTime [clock seconds]
set cycleCount 0
set totalRunTime 0

set parameters {
  {time.arg 4   "Number of hour to run. Time check after finish cycle"}
	{cycle.arg 0   "Number of cycle to run, if cycle is 0 we use time"}
	{id.arg "229"  "Chassy ID get from last IP number. Ex: 192.168.3.X"}
	{slot.arg "15"  "Number of testing blade. It will run test for slot from 1-> N"}
	{vixs.arg "6"  "Number of vixs on each unit. "}
	{prefix.arg "192.168.3"  "Base ip for Chassy."}
  {debug "Turn on debugging, default=off"}
}

set usage "Chassy power cycle test script"
if {[catch {array set options [cmdline::getoptions ::argv $parameters $usage]}]} {
  puts [cmdline::usage $parameters $usage]
  exit
} else {
  set totalRunTime [expr {$options(time) * 60 * 60}]
  parray options
}

if { [string length $options(id)] == 0 } {
	puts "Please input Chassy ID"
	exit
}

array set listSerialNumber {}
#Init array storage for serial number
for {set i 1} {$i < 16} {incr i 1} {
	set listSerialNumber($i) ""
} 

set cnob_slots [list ]
set vixs_ids   [list ] 
#init number of slot
for {set i 1} {$i <= $options(slot) } {incr i 1} {
	lappend cnob_slots $i
} 

#init number of vixs
for {set i 0} {$i < $options(vixs) } {incr i 1} {
	lappend vixs_ids $i 
	#set vixs_ids($i) $i 
} 

set port "$options(prefix).$options(id)"

#parray listSerialNumber
#set endTime [expr {[clock seconds] - $startTime}]
#displayDebug $endTime
#
#displayDebug $port
#displayDebug $totalRunTime
#displayDebug $cycleCount
#displayDebug $startTime
#displayDebug [checkStillRunning]


#parray options
#
#puts "There are $argc arguments to this script"
#puts "The name of this script is $argv0"
#if {$argc > 0} {puts "The other arguments are: $argv" }
#puts "You have these environment variables set:"
