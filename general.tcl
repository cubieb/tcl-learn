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


proc displayDebugArray {arrayInput} {
  upvar $arrayInput arrayContent
  displayDebug ""
  parray arrayContent
  parrayToFile arrayContent
}

proc failSlot {slot} {
	global failCount
	set failCount($slot) [expr $failCount($slot) + 1]
}

proc failVixs {slot vixs} {
	global failCount
	set index "$slot,$vixs"
	set failCount($index) [expr $failCount($index) + 1]
}

proc displayCurrentProcess {force} {
	global failCount
	global failCountTotal
	global listSerialNumber
	global cnob_slots
	global vixs_ids
 

  displayDebug ""
  displayDebug "########## DETAIL FAIL ##########"
  foreach slot $cnob_slots {
  	if {$failCount($slot) > 0 } {
          displayDebug "### SSH-SLOT$slot-SN-$listSerialNumber($slot): $failCount($slot) fails"
          set failCountTotal($slot) [expr $failCountTotal($slot) + 1]
  	}
    foreach vixs_id $vixs_ids {
	    set index "$slot,$vixs_id"
	    if {$failCount($index) > 0 } {
               displayDebug "### SSH-SLOT$slot-SN-$listSerialNumber($slot)-VIXS$vixs_id: $failCount($index) fails"
               set failCountTotal($slot) [expr $failCountTotal($slot) + 1]
	    }
    }
  }

  displayDebug ""
  displayDebug "########## SUMMARY ##########"
  foreach slot $cnob_slots {
  	if {$failCountTotal($slot) > 0 } {
          displayDebug "### SSH-SLOT$slot-SN-$listSerialNumber($slot): FAIL"
  	} else {
          displayDebug "### SSH-SLOT$slot-SN-$listSerialNumber($slot): PASS"
	}
  }
}

# this function to control how long will the test run
proc checkStillRunning {} {
  global options
  global startTime
  global totalRunTime
  global cycleCount
  if { $cycleCount > 0 } {
  	displayCurrentProcess 0
  }

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


#basic configuration
set startTime [clock seconds]
set cycleCount 0
set totalRunTime 0
set port ""
set logFile "error.log"
array set listSerialNumber {}
array set failCount {}
array set failCountTotal {}
#board configuration
set pwrswitch 2
set numberOfPowerCycle 15
#set numberOfPowerCycle 15
set offtime 10
set boot_time     1200
#set boot_time     360
set numberOfRetest 2
set powerCycleCount 0
set powerCycleTime 60

#{time.arg 4   "Number of hour to run. Time check after finish cycle"}
#{cycle.arg 0   "Number of cycle to run, if cycle is 0 we use time"}
set parameters {
	{device.arg "ntsc"  "Type of device for test"}
	{id.arg "229"  "Chassy ID get from last IP number. Ex: 192.168.3.X"}
	{prefix.arg "192.168.3"  "Base ip for Chassy."}
	{startSlot.arg 0   "It will run test for slot from start -> end"}
	{endSlot.arg  15   "It will run test for slot from start -> end"}
	{pwrSwitch.arg  2   "Power control switch "}
	{vixs.arg "6"  "Number of vixs on each unit. "}
	{version.arg "154"  "Firmware version for password"}
  {debug "Turn on debugging, default=off"}
}

set usage "Chassy power cycle test script"
if {[catch {array set options [cmdline::getoptions ::argv $parameters $usage]}]} {
  displayDebug [cmdline::usage $parameters $usage]
  exit
} else {
  #set totalRunTime [expr {$options(time) * 60 * 60}]
	set port "$options(prefix).$options(id)"
  file mkdir "./log_$options(id)"
  set timeStamp [timestampForLog]
	set logFile "./log_$options(id)/$timeStamp.log"
	switch  $options(device) {
		qam48 {
			displayDebug "### QAM48 Test"
			set options(vixs) 0
			set boot_time     360
		}
		assy {
			displayDebug "### ASSY Test"
			set options(vixs) 4
			set boot_time     600
		}
		default {
			displayDebug "### NTSC Test"
		}
	}

	switch  $options(version) {
		154 {
			set password "5VN7DrD3"
		}
		default {
		  set password "BcJFzhB9Cnyr"
		}
	}

	set pwrswitch $options(pwrSwitch)

	displayDebugArray options
}

if { [string length $options(id)] == 0 } {
	puts "Please input Chassy ID"
	exit
}


#Init array storage for serial number
for {set i 0} {$i < 16} {incr i 1} {
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
	set failCountTotal($slot) 0
	foreach vixs_id $vixs_ids {
		set failCount($slot,$vixs_id) 0
	}
}

