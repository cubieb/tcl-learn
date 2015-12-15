#!/usr/bin/expect --

source "tcl.sh"

set testIndex 1

displayDebug $testIndex
set listSerialNumber($testIndex) 4
parray listSerialNumber
set endTime [expr {[clock seconds] - $startTime}]
displayDebug $endTime

set port "$options(prefix).$options(id)"
displayDebug $port
displayDebug $totalRunTime
displayDebug $cycleCount
displayDebug $startTime
displayDebug [checkStillRunning]

