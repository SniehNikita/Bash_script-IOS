#!/bin/bash




# --------FUNCTION--------
# -h function
Helper() {
    echo "POUŽITÍ"
    echo ""
    echo "corona [-h] [FILTERS] [COMMAND] [LOG [LOG2 [...]]"
    echo ""
	echo "COMMAND může být jeden z:"
    echo "  infected — spočítá počet nakažených."
    echo "  merge — sloučí několik souborů se záznamy do jednoho, zachovávající původní pořadí (hlavička bude ve výstupu jen jednou)."
    echo "  gender — vypíše počet nakažených pro jednotlivá pohlaví."
    echo "  age — vypíše statistiku počtu nakažených osob dle věku (bližší popis je níže)."
    echo "  daily — vypíše statistiku nakažených osob pro jednotlivé dny."
    echo "  monthly — vypíše statistiku nakažených osob pro jednotlivé měsíce."
    echo "  yearly — vypíše statistiku nakažených osob pro jednotlivé roky."
    echo "  countries — vypíše statistiku nakažených osob pro jednotlivé země nákazy (bez ČR, tj. kódu CZ)."
    echo "  districts — vypíše statistiku nakažených osob pro jednotlivé okresy."
    echo "  regions — vypíše statistiku nakažených osob pro jednotlivé kraje."
    echo ""
    echo "FILTERS může být kombinace následujících (každý maximálně jednou):"
    echo "  -a DATETIME — after: jsou uvažovány pouze záznamy PO tomto datu (včetně tohoto data). DATETIME je formátu YYYY-MM-DD."
    echo "  -b DATETIME — before: jsou uvažovány pouze záznamy PŘED tímto datem (včetně tohoto data)."
    echo "  -g GENDER — jsou uvažovány pouze záznamy nakažených osob daného pohlaví. GENDER může být M (muži) nebo Z (ženy)."
    echo "  -s [WIDTH] — u příkazů gender, age, daily, monthly, yearly, countries, districts a regions vypisuje data ne číselně, ale graficky v podobě histogramů. Nepovinný parametr WIDTH nastavuje šířku histogramů, tedy délku nejdelšího řádku, na WIDTH. Tedy, WIDTH musí být kladné celé číslo."
    echo "  -d DISTRICT_FILE — pro příkaz districts vypisuje místo LAU 1 kódu okresu jeho jméno. Mapování kódů na jména je v souboru DISTRICT_FILE"
    echo "  -r REGIONS_FILE — pro příkaz regions vypisuje místo NUTS 3 kódu kraje jeho jméno. Mapování kódů na jména je v souboru REGIONS_FILE"
    echo ""
    echo "-h — vypíše nápovědu s krátkým popisem každého příkazu a přepínače."
    
    exit 0;
}




# --------FUNCTION--------
# Prints error massage, given as $1, to stderr
CallError() {
    echo $1 >&2;
}




# --------FUNCTION--------
# Checks date, given as $1, according to the format, given as $2
IsDateCorrect() {
    if [ ! `date -d "$1" +$2` ];
    then
        CallError "[TODO ERROR] Wrong time format";
    fi
}




# --------FUNCTION--------
# Looks for params
FindParams() {
    local i=1;
    local j=$#;
    while [ $i -le $j ] 
    do
        case $1 in
            -h )
                Helper;
                ;;
            infected | merge | gender | age | daily | monthly | yearly | countries | districts | regions )
                if [[ $c = false ]]
                then 
                    c=true;
                    COMMAND=$1;
                else 
                    CallError "[TODO ERROR] Only one command PLEASE";
                fi
                ;;
            -a ) 
                if [[ $a = false ]]
                then 
                    i=$((i + 1));
                    a=true;
                    shift;
                    TIMEAFTER=$1;
                    IsDateCorrect $TIMEAFTER %Y-%m-%d;
                else 
                    CallError "[TODO ERROR] Only one -a paraPAPAm";
                fi
                ;;
            -b ) 
                if [[ $b = false ]]
                then 
                    i=$((i + 1));
                    b=true;
                    shift;
                    TIMEBEFORE=$1;
                    IsDateCorrect $TIMEBEFORE %Y-%m-%d;
                else 
                    CallError "[TODO ERROR] Only one -b paraPAPAm";
                fi
                ;;
            -s )
                if [[ $s = false ]]
                then
                    if [[ $2 =~ ^[0-9]+$ ]]
                    then
                        s=true;
                        WIDTH=$2;
                        shift;
                        i=$((i + 1));
                    else
                        s=true;
                        WIDTH=-1;
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
                        GENDER=$2;
                        g=true;
                        shift;
                        i=$((i + 1));
                    else
                        CallError "[TODO ERROR] -g needs gender (M|Z)";
                    fi
                else
                    CallError "[TODO ERROR] Only one -g";
                fi
                ;;
            -d )
                DISTRICT_FILE=$2;
                d=true;
                shift;
                i=$((i + 1));
                ;;
            -r )
                REGIONS_FILE=$2;
                r=true;
                shift;
                i=$((i + 1));
                ;;
        esac
        i=$((i + 1));
        shift;
    done    
}




# --------FUNCTION--------
# Prints all params
PrintParams() {
    echo "s:" $s ", width:" $WIDTH;
    echo "a:" $a ", time after:" $TIMEAFTER;
    echo "b:" $b ", time before:" $TIMEBEFORE;   
    echo "c:" $c ", command:" $COMMAND;
    echo "g:" $g ", gender:" $GENDER;
    echo "d:" $d ", districts_file:" $DISTRICT_FILE;
    echo "r:" $r ", regions_file:" $REGIONS_FILE;
}








#===========================================================================
#   Main
#===========================================================================

Main() {
    c=false;a=false;b=false;s=false;g=false;d=false;r=false

    FindParams $@;
    PrintParams;
}

Main $@;