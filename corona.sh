#!/bin/bash

Helper() {
	echo "Usage: $0 [-h] [FILTERS] [COMMAND] [LOG [LOG2 [...]]" 1>&2; exit; 
}

CallError() {
    echo $1 >&2
}

IsTimeCorrect() {
    if [ ! `date "+%Y-%m-%d" -d $1` ];
    then
        echo "[TODO ERROR] Wrong time format";exit;        
    fi
}

c=false
a=false
b=false
s=false


i=1;
j=$#;
while [ $i -le $j ] 
do
    #echo $1
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
                echo "[TODO ERROR] Only one command PLEASE";exit 1;
            fi
            ;;
        -a ) 
            if [[ $a = false ]]
            then 
                i=$((i + 1));
                a=true
                shift 1;
                TIMEAFTER=$1;
                IsTimeCorrect $TIMEAFTER
            else 
                echo "[TODO ERROR] Only one -a paraPAPAm";exit 1;
            fi
            ;;
        -b ) 
            if [[ $b = false ]]
            then 
                i=$((i + 1));
                b=true
                shift 1;
                TIMEBEFORE=$1;
                IsTimeCorrect $TIMEBEFORE
            else 
                echo "[TODO ERROR] Only one -b paraPAPAm";exit 1;
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
                echo "[TODO ERROR] Only one -s";exit 1;
            fi
            ;;

    esac
    i=$((i + 1));
    shift 1;
done

echo "s:" $s ", width:" $WIDTH
echo "a:" $a ", time after:" $TIMEAFTER
echo "b:" $b ", time before:" $TIMEBEFORE   
echo "c:" $c ", command:" $COMMAND

echo "end"