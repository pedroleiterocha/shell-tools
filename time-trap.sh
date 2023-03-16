#!/bin/bash

ELAPSED_LIMIT=2000000000  # 2 seconds

# Runs before each command is executed.
function PreCommand() {
    local s=$?
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
        local x="[V]"
        local c=32
    else
        local x="[X $1]"
        local c=31
    fi

    local ELAPSED=$(expr $(TimeNow) - $TIME_START)
    if [ "$ELAPSED" -ge "$ELAPSED_LIMIT" ] || [ "$1" -ne "0" ]; then
        t=$(PrintTime $ELAPSED)
        if [ -n "$TIME_PARTIAL" ]; then
            t="($(PrintTime $(expr $(TimeNow) - $TIME_PARTIAL))), Total: $t"
        fi
        echo -e "\033[03;${c}m"$(PadMiddle "$x" "$t")"\033[00m"
    fi
}

function TimeNow() {
    date +%s%N
}

function PrintTime() {
    local t=$1
    local B=1000000000

    local d=$((t/B/60/60/24))
    local h=$((t/B/60/60%24))
    local m=$((t/B/60%60))
    local s=$((t/B%60))
    local u=$((t/1000000%1000))

    if [ $d -gt 0 ]; then
        printf "%dd " $d
    fi
    if [ $h -gt 0 ]; then
        printf "%dh " $h
    fi
    if [ $m -gt 0 ]; then
        printf "%dm " $m
    fi
    if [ $s -gt 0 ] || [ $u -gt 0 ]; then
        printf "%'d.%03ds" $s $u
    fi
    printf '\n'
}

function PadMiddle() {
    local s=$(($COLUMNS - ${#1} - ${#2} - 2))
    local b=$(printf '=%.0s' `seq 1 $s`)
    echo $1 $b $2
}

# Initialize.
PROMPT_COMMAND="PostCommand"
trap "PreCommand" DEBUG
