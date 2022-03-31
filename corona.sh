#!/bin/bash

# corona.sh
# Řešení IOS PROJ 1, 25.3.2022
# Autor: Nikita Sniehovskyi, FIT



POSIXLY_CORRECT=yes



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




# Prints error massage, given as $1, to stderr
CallError() {
    echo $1 >&2;
    exit 1;
}




# Checks date, given as $1, according to the format, given as $2
IsDateCorrect() {
    #very very very slow
    if [ ! `date -d "$1" +$2` ];
    then
        CallError "[TODO ERROR] Wrong time format: "$1;
    fi
}




IsAgeCorrect() {
    if [[ ! $1 =~ [0-9]* ]]
    then
        CallError "Wrong age: "{$1};
    fi
}




IsSexCorrect() {
    if [[ ! ($1 = "M" || $1 = "Z") ]]
    then
        CallError "Wrong sex: "{$1};
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
            * )
                if [[ $1 =~ .*(\.csv|\.gz|\.bz2)$ ]]
                then
                    inputFileNames[${#inputFileNames[@]}]=$1
                else
                    CallError "Unknown param";
                fi
                ;;
        esac
        i=$((i + 1));
        shift;
    done    
}




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




#
VariablesDeclaration() {
    case $COMMAND in
        "merge" )
            commandFunction=null;
            ;;
        "infected" )
            INFECTED=0;
            commandFunction=Infected;
            ;;
        "gender" )
            GENDERM=0;
            GENDERZ=0;
            commandFunction=Gender;
            ;;
        "age" )
            min0=0;
            min6=0;
            min16=0;
            min26=0;
            min36=0;
            min46=0;
            min56=0;
            min66=0;
            min76=0;
            min86=0;
            min96=0;
            min105=0;
            minNone=0;
            commandFunction=Age;
            ;;
        "daily" )
            commandFunction=Daily;
            ;;
        "monthly" )
            commandFunction=Monthly;
            ;;
        "yearly" )
            commandFunction=Yearly;
            ;;
        "districts" )
            commandFunction=Districts;
            ;;
        "regions" )
            commandFunction=Regions;
    esac
}




# Writes $1 $2 times
WriteCharNTimes() {
    for (( i = 0 ; i < $2 ; i++ )); do echo -n $1 
    done; 
}




#Outputs output
WriteOutput() {
    case $COMMAND in
        "infected" )
            echo $INFECTED;
            ;;
        "gender" )
            if [[ $s = true ]]
            then
                if [[ $WIDTH = -1  ]]; then WIDTH=100000; fi
                echo -n "M: "; WriteCharNTimes "#" $((GENDERM/WIDTH)); echo "";
                echo -n "Z: "; WriteCharNTimes "#" $((GENDERZ/WIDTH)); echo "";
            else                
                echo "M: "$GENDERM;
                echo "Z: "$GENDERZ;
            fi
            ;;
        "age" )
            if [[ $s = true ]]
            then
                if [[ $WIDTH = -1  ]]; then WIDTH=10000; fi
                echo -n "0-5    : "; WriteCharNTimes "#" $((min0/WIDTH)); echo "";
                echo -n "6-15   : "; WriteCharNTimes "#" $((min6/WIDTH)); echo "";
                echo -n "16-25  : "; WriteCharNTimes "#" $((min16/WIDTH)); echo "";
                echo -n "26-35  : "; WriteCharNTimes "#" $((min26/WIDTH)); echo "";
                echo -n "36-45  : "; WriteCharNTimes "#" $((min36/WIDTH)); echo "";
                echo -n "46-55  : "; WriteCharNTimes "#" $((min46/WIDTH)); echo "";
                echo -n "56-65  : "; WriteCharNTimes "#" $((min56/WIDTH)); echo "";
                echo -n "66-75  : "; WriteCharNTimes "#" $((min66/WIDTH)); echo "";
                echo -n "76-85  : "; WriteCharNTimes "#" $((min76/WIDTH)); echo "";
                echo -n "86-95  : "; WriteCharNTimes "#" $((min86/WIDTH)); echo "";
                echo -n "96-105 : "; WriteCharNTimes "#" $((min96/WIDTH)); echo "";
                echo -n ">105   : "; WriteCharNTimes "#" $((min105/WIDTH)); echo "";
                echo -n "None   : "; WriteCharNTimes "#" $((minNone/WIDTH)); echo "";
            else
                echo "0-5    : "$min0;
                echo "6-15   : "$min6;
                echo "16-25  : "$min16;
                echo "26-35  : "$min26;
                echo "36-45  : "$min36;
                echo "46-55  : "$min46;
                echo "56-65  : "$min56;
                echo "66-75  : "$min66;
                echo "76-85  : "$min76;
                echo "86-95  : "$min86;
                echo "96-105 : "$min96;
                echo ">105   : "$min105;
                echo "None   : "$minNone
            fi
            ;;
        "daily" )
            if [[ $s = true && $WIDTH = -1 ]]; then WIDTH=500; fi
            keyLast="0-0-0"
            for kkey in ${!keyValueArray[@]}; do
                keyMin="9999-99-99"
                for key in ${!keyValueArray[@]}; do
                    if [[ $key < $keyMin && $key > $keyLast ]]
                    then
                        keyMin=$key;
                    fi
                done
                if [[ $keyMin = "9999-99-99" ]]
                then
                    keyMin="None";
                fi

                if [[ $s = true ]]
                then
                    echo -n ${keyMin}":"; WriteCharNTimes "#" $((keyValueArray[${keyMin}]/WIDTH)); echo "";
                else
                    echo ${keyMin}":" ${keyValueArray[${keyMin}]};
                fi

                keyLast=$keyMin;
            done
            ;;
        "monthly" )
            if [[ $s = true && $WIDTH = -1 ]]; then WIDTH=10000; fi
            keyLast="0-0"
            for kkey in ${!keyValueArray[@]}; do
                keyMin="9999-99"
                for key in ${!keyValueArray[@]}; do
                    if [[ $key < $keyMin && $key > $keyLast ]]
                    then
                        keyMin=$key;
                    fi
                done
                if [[ $keyMin = "9999-99" ]]
                then
                    keyMin="None";
                fi
                
                if [[ $s = true ]]
                then
                    echo -n ${keyMin}":"; WriteCharNTimes "#" $((keyValueArray[${keyMin}]/WIDTH)); echo "";
                else
                    echo ${keyMin}":" ${keyValueArray[${keyMin}]};
                fi

                keyLast=$keyMin;
            done
            ;;
        "yearly" )
            if [[ $s = true && $WIDTH = -1 ]]; then WIDTH=100000; fi
            keyLast="0"
            for kkey in ${!keyValueArray[@]}; do
                keyMin="9999"
                for key in ${!keyValueArray[@]}; do
                    if [[ $key < $keyMin && $key > $keyLast ]]
                    then
                        keyMin=$key;
                    fi
                done
                if [[ $keyMin = "9999" ]]
                then
                    keyMin="None";
                fi
                
                if [[ $s = true ]]
                then
                    echo -n ${keyMin}":"; WriteCharNTimes "#" $((keyValueArray[${keyMin}]/WIDTH)); echo "";
                else
                    echo ${keyMin}":" ${keyValueArray[${keyMin}]};
                fi

                keyLast=$keyMin;
            done
            ;;
        "regions" )
            if [[ $s = true && $WIDTH = -1 ]]; then WIDTH=100000; fi
            keyLast="0"
            for kkey in ${!keyValueArray[@]}; do
                keyMin="CZ09999999999";
                for key in ${!keyValueArray[@]}; do
                    if [[ $key < $keyMin && $key > $keyLast ]]
                    then
                        keyMin=$key;
                    fi
                done
                if [[ $keyMin = "CZ09999999999" ]]
                then
                    keyMin="None";
                fi
                
                if [[ $s = true ]]
                then
                    echo -n ${keyMin}":"; WriteCharNTimes "#" $((keyValueArray[${keyMin}]/WIDTH)); echo "";
                else
                    echo ${keyMin}":" ${keyValueArray[${keyMin}]};
                fi

                keyLast=$keyMin;
            done
            ;;
        "districts" )
            if [[ $s = true && $WIDTH = -1 ]]; then WIDTH=100000; fi
            keyLast="0"
            for kkey in ${!keyValueArray[@]}; do
                keyMin="CZ09999999999";
                for key in ${!keyValueArray[@]}; do
                    if [[ $key < $keyMin && $key > $keyLast ]]
                    then
                        keyMin=$key;
                    fi
                done
                if [[ $keyMin = "CZ09999999999" ]]
                then
                    keyMin="None";
                fi
                
                if [[ $s = true ]]
                then
                    echo -n ${keyMin}":"; WriteCharNTimes "#" $((keyValueArray[${keyMin}]/WIDTH)); echo "";
                else
                    echo ${keyMin}":" ${keyValueArray[${keyMin}]};
                fi

                keyLast=$keyMin;
            done
            ;;
    esac
}


Eccho() {
    echo "=========="
    echo \"$1\"
    echo "=========="
}




# infected
Infected() {
    INFECTED=$((INFECTED+1));
}




# Gender
Gender() {
    if [[ $pohlavi = "M" ]]
    then
        GENDERM=$((GENDERM+1));
    else
        GENDERZ=$((GENDERZ+1));
    fi
}




# age
Age() {
    if [[ $vek = "" ]]
    then
        minNone=$((minNone+1));        
    elif [[ 0 -le vek && vek -le 5 ]]
    then
        min0=$((min0+1));
    elif [[ 6 -le vek && vek -le 15 ]]
    then
        min6=$((min6+1));
    elif [[ 16 -le vek && vek -le 25 ]]
    then
        min16=$((min16+1));
    elif [[ 26 -le vek && vek -le 35 ]]
    then
        min26=$((min26+1));
    elif [[ 36 -le vek && vek -le 45 ]]
    then
        min36=$((min36+1));
    elif [[ 46 -le vek && vek -le 55 ]]
    then
        min46=$((min46+1));
    elif [[ 56 -le vek && vek -le 65 ]]
    then
        min56=$((min56+1));
    elif [[ 66 -le vek && vek -le 75 ]]
    then
        min66=$((min66+1));
    elif [[ 76 -le vek && vek -le 85 ]]
    then
        min76=$((min76+1));
    elif [[ 86 -le vek && vek -le 95 ]]
    then
        min86=$((min86+1));
    elif [[ 96 -le vek && vek -le 105 ]]
    then
        min96=$((min96+1));
    elif [[ 105 -le vek ]]
    then
        min105=$((min6+1));
    fi
}




#daily
Daily() {
    keyValueArray[$datum]=$((keyValueArray[$datum]+1));
}




#monthly
Monthly() {
    #take 7 first chars
    datum=${datum::7};
    keyValueArray[$datum]=$((keyValueArray[$datum]+1));
}




#yearly
Yearly() {
    #take 4 first chars
    datum=${datum::4};
    keyValueArray[$datum]=$((keyValueArray[$datum]+1));
}




#districts
Districts() {
    if [[ $okres_lau_kod = "" ]]
    then
        okres_lau_kod="None";
    fi
    keyValueArray[$okres_lau_kod]=$((keyValueArray[$okres_lau_kod]+1));
}




#regions
Regions() {
    if [[ $kraj_nuts_kod = "" ]]
    then
        kraj_nuts_kod="None";
    fi
    keyValueArray[$kraj_nuts_kod]=$((keyValueArray[$kraj_nuts_kod]+1));
}




Counter() {
    IFS=","
    read -a arr <<< $2
    IFS=$ogIFS

    pohlavi=${arr[3]}   
    IsSexCorrect $pohlavi;   

    vek=${arr[2]}
    IsAgeCorrect $vek;

    datum=${arr[1]}
    IsDateCorrect $datum %Y-%m-%d;

    case $COMMAND in
        "regions" )
            kraj_nuts_kod=${arr[4]}
            ;;
        "districts" )
            okres_lau_kod=${arr[5]}
            ;;
    esac
    #nakaza_v_zahranici=${arr[6]}
    #nakaza_zeme_csu_kod=${arr[7]}
    #reportovano_khs=${arr[8]}

    if [[ (($a = true && $TIMEAFTER < $datum) || ($a = false)) && (($b = true && $TIMEBEFORE > $datum) || ($b = false)) && (($g = true && $GENDER = $pohlavi) || ($g = false)) ]]
    then
        $1; #calls function
    fi

}




# Reads file, calls function $1
ReadFromFile() {
    file=$2;
    if [[ $2 =~ .*\.bz2$ ]]
    then
        var=`bzcat $2 | awk 'BEGIN { RS = "\n" } {print $0} '`
    elif [[ $2 =~ .*\.gz$ ]]
    then
        var=`zcat $2 | awk 'BEGIN { RS = "\n" } {print $0} '`
    else
        var=`cat $2 | awk 'BEGIN { RS = "\n" } {print $0} '`
    fi
    var="${var#*$'\n'}"

    
    #echo -n "#"
    if [[ ! $COMMAND = "merge" ]]
    then
        for line in $var; do Counter $1 $line; done
    else
        for line in $var; do echo $line; done
    fi
}



# Reads stdin, calls function $1
ReadFromStdin() {
    local i=1;
    while read line
    do
        #echo -n "#"
        if [[ $i = 1 ]]
        then 
            i=2
            continue;        
        fi

        if [[ ! $COMMAND = "merge" ]]
        then
            Counter $1 $line
        else
            echo $line;
        fi
    done < "${123:-/dev/stdin}" # reads from stdin
}




#===========================================================================
#   Main
#===========================================================================

Main() {
    c=false;a=false;b=false;s=false;g=false;d=false;r=false;
    COMMAND="merge";
    inputFileNames=();
    declare -A keyValueArray;
    ogIFS=$IFS;



    FindParams $@;
    VariablesDeclaration;


    if [[ $COMMAND = "merge" ]]
    then
        echo "id,datum,vek,pohlavi,kraj_nuts_kod,okres_lau_kod,nakaza_v_zahranici,nakaza_zeme_csu_kod,reportovano_khs"
    fi        

    # if input is in stdin, in array will be nothing to send
    if [[ ${#inputFileNames[@]} > 0 ]]
    then
        for input in ${inputFileNames[@]}; do
            ReadFromFile $commandFunction $input;
        done
    else
        ReadFromStdin $commandFunction;
    fi

    WriteOutput;
}

Main $@;