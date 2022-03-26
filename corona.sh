#!/bin/bash


# -h function
Helper() {
	echo "Usage: $0 [-h] [FILTERS] [COMMAND] [LOG [LOG2 [...]]" 1>&2;
    echo "-h : Help. (You see this message now)"
    echo ""
    echo "FILTERS can be:"
    echo "-a date (YYYY-MM-DD) : search after this date"
    echo "-b date (YYYY-MM-DD) : search before this date"
    echo "-g GENDER (M (for men) or Z (for women)) : searches for only one gender"
    echo "-s [WIDTH](>0) : for gender, age, daily, monthly, yearly, countries, districts and regions commands shows histogram" 

    exit 0;
}



# Prints error massage, given as $1, to stderr
CallError() {
    echo $1 >&2
}



# Checks date, given as $1, according to the format, given as $2
IsDateCorrect() {
    if [ ! `date -d "$1" +$2` ];
    then
        CallError "[TODO ERROR] Wrong time format";
    fi
}



# Looks for params
FindParams() {
    local i=1;
    local j=$#;
    while [ $i -le $j ] 
    do
        case $1 in
            -h )
                Helper
                ;;
            infected | merge | gender | age | daily | monthly | yearly | countries | districts | regions )
                if [[ $c = false ]]
                then 
                    c=true
                    COMMAND=$1;
                else 
                    CallError "[TODO ERROR] Only one command PLEASE";
                fi
                ;;
            -a ) 
                if [[ $a = false ]]
                then 
                    i=$((i + 1));
                    a=true
                    shift;
                    TIMEAFTER=$1;
                    IsDateCorrect $TIMEAFTER %Y-%m-%d
                else 
                    CallError "[TODO ERROR] Only one -a paraPAPAm";
                fi
                ;;
            -b ) 
                if [[ $b = false ]]
                then 
                    i=$((i + 1));
                    b=true
                    shift;
                    TIMEBEFORE=$1;
                    IsDateCorrect $TIMEBEFORE %Y-%m-%d
                else 
                    CallError "[TODO ERROR] Only one -b paraPAPAm";
                fi
                ;;
            -s )
                if [[ $s = false ]]
                then
                    if [[ $2 =~ ^[0-9]+$ ]]
                    then
                        s=true 
                        WIDTH=$2
                        shift;
                        i=$((i + 1))
                    else
                        s=true
                        WIDTH=-1
                    fi
                else
                    CallError "[TODO ERROR] Only one -s";
                fi
                ;;
            -g )
                if [[ $g = false ]]
                then
                    if [[ $2 = "M" || $2 = "Z" ]]
                    then
                        GENDER=$2
                        g=true
                        shift;
                        i=$((i + 1))
                    else
                        CallError "[TODO ERROR] -g needs gender (M|Z)";
                    fi
                else
                    CallError "[TODO ERROR] Only one -g";
                fi
                ;;
        esac
        i=$((i + 1));
        shift;
    done    
}








#===========================================================================
#   Main
#===========================================================================

Main() {
    c=false
    a=false
    b=false
    s=false
    g=false

    FindParams $@


    echo "s:" $s ", width:" $WIDTH
    echo "a:" $a ", time after:" $TIMEAFTER
    echo "b:" $b ", time before:" $TIMEBEFORE   
    echo "c:" $c ", command:" $COMMAND
    echo "g:" $g ", gender:" $GENDER

    echo "end"
}

Main $@