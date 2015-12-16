#!/usr/bin/expect --

set send_slow { 1 .010 }
log_user 0
exp_internal 0

set cnob_slots [list 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
#set cnob_slots [list 6]
set vixs_ids   [list 0 1 2 3 4 5] 

set pauseonfail nottrue

set offtime 10
set pwrswitch 8
#the following are set in external environment
#set pwraddr 192.168.3.226
#set pwruser admin
#set pwrpswd 1234


set port "192.168.3.229"
set uboot_timeout  20
set linux_timeout 180
set boot_time     1200
set username "root"
#set password "BcJFzhB9Cnyr"
set password "5VN7DrD3"
set vixs_wait      30
set ping_timeout   15
set vixs_retry     1


set uboot_start "U-Boot"
set uboot_login "Hit any key to stop autoboot:"
set linux_login "clifford login:"

set uboot_prompt "Clifford U-Boot >"
set linux_prompt "root@.*#"
set prompt "#"

set cmd {}


proc tstamp {} {
  exec date "+%Y-%m-%d@%H:%M:%S"
}

proc pausecheck {} {
  global pauseonfail

  if { "$pauseonfail" == "true" } { 
    set timeout -1
    send_user "hit enter to continue..."
    expect_user -re "(.*)\n"
    send_user "\r"
  }
}

proc power {state} {
  global pwrswitch
  exec powerctrl [set pwrswitch][set state]
}

#include tcl for extra function
#include it here to overwrite port if need, and have top proc 
source "general.tcl"

proc boottest {} {
  #global uboot_login
  #global linux_login
  #global uboot_timeout
  #global linux_timeout
  #global vixs_wait
  #global ping_timeout
  #global vixs_retry
  global listSerialNumber
  global password
  global port
  #global prompt
  global linux_prompt
  global cnob_slots
  global vixs_ids

  set ipaddr [lindex $port 0]
  set ipport [lindex $port 1]

  log_user 1
  set timeout 10
  spawn ssh root@$ipaddr
  expect {
    timeout          { displayDebugInNewLine "###FAIL SSH-MASTER"
                       pausecheck
                       return 
                     }
    "password:"      { sleep 1; send "$password\r" 
                     }
    "continue connecting" { send "yes\r"
                            exp_continue
                     }
    "Connection refused" { displayDebugInNewLine "###FAIL SSH-MASTER"
                       pausecheck
                       return 
                     }
  }

  expect -re "$linux_prompt"
  displayDebugInNewLine "###CHECKPOINT SSH-MASTER"
  send "uptime\r"
  expect -re "$linux_prompt"
  send "rm ~/.ssh/known_hosts\r"
  expect -re "$linux_prompt"

  foreach slot $cnob_slots {

    send "ssh slot$slot\r"
    expect {
      timeout          { displayDebugInNewLine "###FAIL SSH-SLOT$slot-SN-$listSerialNumber($slots)"
                         expect -re "$linux_prompt"
                         pausecheck
                         continue
                       }
      "continue connecting" { send "yes\r"
                              exp_continue
                            }
      "password:"      { #sleep 1
                         send "$password\r" 
                       }
    }

    displayDebugInNewLine "###CHECKPOINT SSH-SLOT$slot"
    expect -re "$linux_prompt"
    send "uptime\r"
    expect -re "$linux_prompt"

    updateSlotSerialNumber $spawn_id $slot		 

    foreach v $vixs_ids {
      send "ping -f -c 10 -w 5 vixs$v\r"
      expect {
                   timeout { displayDebugInNewLine "###FAIL SLOT$slot-SN-$listSerialNumber($slots)-VIXS$v"
                             pausecheck
                           }
        " 0% packet loss"  { #sleep 1
                             #expect "*"
                             displayDebugInNewLine "###CHECKPOINT SLOT$slot-$listSerialNumber($slots)-VIXS$v"
                           }
      }

      expect -re "$linux_prompt"

    }

    set timeout 10

    send "exit\r"
    expect -re "$linux_prompt"
  }

  send "exit\r"
  expect -re "$linux_prompt" return
}

proc powerCycleTest {} {
	set powerCycleCount 0
	set powerCycleTime 60
	power off
	sleep 2
	set powerCycleCount [expr $powerCycleCount + 1]
	displayDebug "###WAITING $powerCycleTime seconds"
	power on
	sleep $powerCycleTime
}

proc powerBootTest {} {
	global test
	global boot_time
	global offtime

  set test [expr $test + 1]
  power off
  sleep 2
	power on
	displayDebug "###POWERON"
	displayDebug "###TRIAL $test"

	displayDebug "###WAITING $boot_time seconds"
	sleep $boot_time
	displayDebug "###CHECKING"

	boottest

  displayDebug "###"
  power off
  displayDebug "###POWEROFF [tstamp]"

  sleep $offtime
  log_user 0
  expect *
  displayDebug "###"
  sleep 1
  log_user 1
}


displayDebug "###TESTSTART [tstamp]"

set pass 0
set fail 0
set test 0

#power on
#displayDebug "###POWERON [tstamp]"
#displayDebug "###TRIAL $test"

#displayDebug "###WAITING $boot_time seconds"
#sleep $boot_time
#displayDebug "###CHECKING [tstamp]"
powerBootTest


displayDebug "###POWERCYCLE [tstamp]"
for {set i 0} { $i < $numberOfPowerCycle } {incr i} {
	powerCycleTest
}

for {set i 0} { $i < $numberOfRetest } {incr i} {
	powerBootTest
}

power off
exit 0
