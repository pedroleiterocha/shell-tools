#!/bin/bash

ELAPSED_LIMIT=500000000

# Runs before each command is executed.
function PreCommand() {
    s=$?
    if [ -z "$AT_PROMPT" ] && [ -n "$TIME_START" ]; then
        PrintElapsedTime $s
        TIME_PARTIAL=$(TimeNow)
        return
    fi
    unset AT_PROMPT
    TIME_START=$(TimeNow)
}

# Runs after all commands have been executed.
FIRST_PROMPT=1
function PostCommand() {
    AT_PROMPT=1

    if [ -n "$FIRST_PROMPT" ]; then
        unset FIRST_PROMPT
        return
    fi

    unset TIME_PARTIAL
    unset TIME_START
}

# Prints the elapsed time since the last command started if the time is greater than
# ELAPSED_LIMIT or if the last command did not exit with zero.
function PrintElapsedTime() {
    if [ "$1" -eq "0" ]; then
        x="[V]"
        c=32
    else
        x="[X $1]"
        c=31
    fi

    ELAPSED=$(expr $(TimeNow) - $TIME_START)
    if [ "$ELAPSED" -ge "$ELAPSED_LIMIT" ] || [ "$1" -ne "0" ]; then
        t=$(MiliFromNano $ELAPSED)
        if [ -n "$TIME_PARTIAL" ]; then
            t="($(MiliFromNano $(expr $(TimeNow) - $TIME_PARTIAL))), Total: $t"
        fi
        echo -e "\033[03;${c}m"$(PadMiddle "$x" "$t")"\033[00m"
    fi
}

function TimeNow() {
    date +%s%N
}

function MiliFromNano() {
    printf "%'d.%03d ms" $(($1/1000000)) $(($1/1000%1000))
}

function PadMiddle() {
    s=$(($COLUMNS - ${#1} - ${#2} - 2))
    b=$(printf '=%.0s' `seq 1 $s`)
    echo $1 $b $2
}

# Initialize.
PROMPT_COMMAND="PostCommand"
trap "PreCommand" DEBUG
