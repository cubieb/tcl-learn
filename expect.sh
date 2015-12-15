#!/usr/bin/expect --

set RUN_IN_TIME 0
set RUN_IN_CYCLE 0
set IS_DEBUG 0

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo "$package - Pico Power Cycle Test for Chassy"
            echo " "
            echo "$package [options] application [arguments]"
            echo " "
            echo "options:"
            echo "-t        How long the script will be run. the default value will be for"
			echo "-c        Specify an how many cycles to run (higher priority then time)"
            echo "-d        Display debug information"
            exit 0
            ;;
        -t)
            shift
            if test $# -gt 0; then
                export RUN_IN_TIME=$1
            else
                echo "no time specified"
                exit 1
            fi
            shift
            ;;
        -c)
            shift
            if test $# -gt 0; then
                export RUN_IN_CYCLE=$1
            else
                echo "no cycle specified"
                exit 1
            fi
            shift
            ;;
        -d)
        	export IS_DEBUG=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

echo $RUN_IN_TIME
echo $RUN_IN_CYCLE
echo $IS_DEBUG
	
