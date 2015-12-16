#!/usr/bin/expect --

package require cmdline

proc timestamp {} {
  return [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
}

proc timestampForLog {} {
  return [clock format [clock seconds] -format "%Y%m%d_%H-%M-%S"]
}

proc displayTime {time} {
  set hours [expr $time / 3600]
  set minutes [expr ($time - $hours *3600) / 60]
  set seconds [expr $time - $hours *3600 - $minutes*60]
  return "$hours hours $minutes minutes $seconds seconds"
}

proc parrayToFile { a {pattern *}} {
  global logFile
  upvar 1 $a array
  set chan [open $logFile a]
  if {![array exists array]} {
    return -code error "\"$a\" isn't an array"
  }
  set maxl 0
  set names [lsort [array names array $pattern]]
  foreach name $names {
    if {[string length $name] > $maxl} {
      set maxl [string length $name]
    }
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name $names {
    set nameString [format %s(%s) $a $name]
    puts $chan [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  close $chan
}

proc displayDebug {content} {
  global logFile
  set chan [open $logFile a]
	puts $chan "[timestamp]: $content"
	puts "[timestamp]: $content"
  close $chan
}

proc displayDebugInNewLine {content} {
  displayDebug ""
  displayDebug $content
}

p
proc displayDebugArray {arrayInput} {
  upvar $arrayInput arrayContent
  displayDebug ""
  parray arrayContent
  parrayToFile arrayContent
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
  incr cycleCount
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
set port ""
set logFile "error.log"

set parameters {
  {time.arg 4   "Number of hour to run. Time check after finish cycle"}
	{cycle.arg 0   "Number of cycle to run, if cycle is 0 we use time"}
	{id.arg "229"  "Chassy ID get from last IP number. Ex: 192.168.3.X"}
	{prefix.arg "192.168.3"  "Base ip for Chassy."}
	{startSlot.arg 1   "It will run test for slot from start -> end"}
	{endSlot.arg  15   "It will run test for slot from start -> end"}
	{vixs.arg "6"  "Number of vixs on each unit. "}
  {debug "Turn on debugging, default=off"}
}

set usage "Chassy power cycle test script"
if {[catch {array set options [cmdline::getoptions ::argv $parameters $usage]}]} {
  displayDebug [cmdline::usage $parameters $usage]
  exit
} else {
  set totalRunTime [expr {$options(time) * 60 * 60}]
	set port "$options(prefix).$options(id)"
  file mkdir "./log_$options(id)"
  set timeStamp [timestampForLog]
	set logFile "./log_$options(id)/$timeStamp.log"

  displayDebugArray options
}

if { [string length $options(id)] == 0 } {
	puts "Please input Chassy ID"
	exit
}

array set listSerialNumber {}
array set failCount {}

#Init array storage for serial number
for {set i 1} {$i < 16} {incr i 1} {
	set listSerialNumber($i) ""
} 

set cnob_slots [list ]
set vixs_ids   [list ] 
#init number of slot
for {set i $options(startSlot)} {$i <= $options(endSlot) } {incr i 1} {
	lappend cnob_slots $i
} 

#init number of vixs
for {set i 0} {$i < $options(vixs) } {incr i 1} {
	lappend vixs_ids $i 
	#set vixs_ids($i) $i 
} 


foreach slot $cnob_slots {
  set failCount($slot) 0
  foreach vixs_id $vixs_ids {
    set failCount("$slot,$vixs_id") 0
  }
}
