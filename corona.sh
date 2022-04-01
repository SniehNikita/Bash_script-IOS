#!/bin/bash

# corona.sh
# Řešení IOS PROJ 1, 25.03.2022 - 01.04.2022
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


# Checks date, given as $1, according to the format, given as $2
IsDateCorrect() {
    #very very very slow
    if [ ! `date -d "$1" +$2` ];
    then
        CallError "Wrong time format: "$1;
    fi
}




# Prints error massage, given as $1, to stderr
CallError() {
    echo $1 >&2;
    exit 1;
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
                if [[ $c = 0 ]]
                then 
                    c=1;
                    COMMAND=$1;
                else 
                    CallError "Only one command PLEASE";
                fi
                ;;
            -a ) 
                if [[ $a = 0 ]]
                then 
                    i=$((i + 1));
                    a=1;
                    shift;
                    TIMEAFTER=$1;
                    IsDateCorrect $TIMEAFTER %Y-%m-%d;
                else 
                    CallError "Only one -a paraPAPAm";
                fi
                ;;
            -b ) 
                if [[ $b = 0 ]]
                then 
                    i=$((i + 1));
                    b=1;
                    shift;
                    TIMEBEFORE=$1;
                    IsDateCorrect $TIMEBEFORE %Y-%m-%d;
                else 
                    CallError "Only one -b paraPAPAm";
                fi
                ;;
            -s )
                if [[ $s = 0 ]]
                then
                    if [[ $2 =~ ^[0-9]+$ ]]
                    then
                        s=1;
                        WIDTH=$2;
                        shift;
                        i=$((i + 1));
                    else
                        s=1;
                        WIDTH=-1;
                    fi
                else
                    CallError "Only one -s";
                fi
                ;;
            -g )
                if [[ $g = 0 ]]
                then
                    if [[ $2 = "M" || $2 = "Z" ]]
                    then
                        GENDER=$2;
                        g=1;
                        shift;
                        i=$((i + 1));
                    else
                        CallError "-g needs gender (M|Z)";
                    fi
                else
                    CallError "Only one -g";
                fi
                ;;
            -d )
                DISTRICT_FILE=$2;
                d=1;
                shift;
                i=$((i + 1));
                ;;
            -r )
                REGIONS_FILE=$2;
                r=1;
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





#Outputs output
WriteOutput() {
    case $COMMAND in
        "infected" )
            echo $INFECTED;
            ;;
        "gender" )
            if [[ $s = 1 ]]
            then
                if [[ $WIDTH != -1 && ($GENDERM -le $GENDERZ) ]]; then numEqv=$(($GENDERZ)); else numEqv=$(($GENDERM)); fi
                if [[ $WIDTH = -1  ]]; then WIDTH=100000; numEqv=$(($WIDTH*$WIDTH)); fi
                echo -n "M: "; WriteCharNTimes "#" $(($GENDERM*$WIDTH/$numEqv)); echo "";
                echo -n "Z: "; WriteCharNTimes "#" $(($GENDERZ*$WIDTH/$numEqv)); echo "";
            else                
                echo "M: "$GENDERM;
                echo "Z: "$GENDERZ;
            fi
            ;;
        "age" )
            for i in {1..5}; do n=$i; keyValueArray["0"]=$((${keyValueArray["0"]}+${keyValueArray[$n]}+0)); done
            for i in {7..15}; do n=$i; keyValueArray["6"]=$((${keyValueArray["6"]}+${keyValueArray[$n]}+0)); done
            for i in {17..25}; do n=$i; keyValueArray["16"]=$((${keyValueArray["16"]}+${keyValueArray[$n]}+0)); done
            for i in {27..35}; do n=$i; keyValueArray["26"]=$((${keyValueArray["26"]}+${keyValueArray[$n]}+0)); done
            for i in {37..45}; do n=$i; keyValueArray["36"]=$((${keyValueArray["36"]}+${keyValueArray[$n]}+0)); done
            for i in {47..55}; do n=$i; keyValueArray["46"]=$((${keyValueArray["46"]}+${keyValueArray[$n]}+0)); done
            for i in {57..65}; do n=$i; keyValueArray["56"]=$((${keyValueArray["56"]}+${keyValueArray[$n]}+0)); done
            for i in {67..75}; do n=$i; keyValueArray["66"]=$((${keyValueArray["66"]}+${keyValueArray[$n]}+0)); done
            for i in {77..85}; do n=$i; keyValueArray["76"]=$((${keyValueArray["76"]}+${keyValueArray[$n]}+0)); done
            for i in {87..95}; do n=$i; keyValueArray["86"]=$((${keyValueArray["86"]}+${keyValueArray[$n]}+0)); done
            for i in {97..105}; do n=$i; keyValueArray["96"]=$((${keyValueArray["96"]}+${keyValueArray[$n]}+0)); done
            for i in {107..200}; do n=$i; keyValueArray["106"]=$((${keyValueArray["106"]}+${keyValueArray[$n]}+0)); done

            if [[ $s = 1 ]]
            then
                if [[ $WIDTH -ne -1 ]]
                then
                    max="None";
                    for i in {0..107}; do
                        if [[ ${keyValueArray[$i]} -gt  ${keyValueArray[$max]} ]]
                        then
                            max=$i;
                        fi
                    done
                    numEqv=$((${keyValueArray[$max]}));
                else
                    WIDTH=10000;
                    numEqv=$(($WIDTH*$WIDTH));
                fi

                echo -n "0-5    : "; WriteCharNTimes "#" $(($((${keyValueArray["0"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "6-15   : "; WriteCharNTimes "#" $(($((${keyValueArray["6"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "16-25  : "; WriteCharNTimes "#" $(($((${keyValueArray["16"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "26-35  : "; WriteCharNTimes "#" $(($((${keyValueArray["26"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "36-45  : "; WriteCharNTimes "#" $(($((${keyValueArray["36"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "46-55  : "; WriteCharNTimes "#" $(($((${keyValueArray["46"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "56-65  : "; WriteCharNTimes "#" $(($((${keyValueArray["56"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "66-75  : "; WriteCharNTimes "#" $(($((${keyValueArray["66"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "76-85  : "; WriteCharNTimes "#" $(($((${keyValueArray["76"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "86-95  : "; WriteCharNTimes "#" $(($((${keyValueArray["86"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "96-105 : "; WriteCharNTimes "#" $(($((${keyValueArray["96"]}*$WIDTH))/$numEqv)); echo "";
                echo -n ">105   : "; WriteCharNTimes "#" $(($((${keyValueArray["106"]}*$WIDTH))/$numEqv)); echo "";
                echo -n "None   : "; WriteCharNTimes "#" $(($((${keyValueArray["None"]}*$WIDTH))/$numEqv)); echo "";
            else
                echo "0-5    : "${keyValueArray["0"]};
                echo "6-15   : "${keyValueArray["6"]};
                echo "16-25  : "${keyValueArray["16"]};
                echo "26-35  : "${keyValueArray["26"]};
                echo "36-45  : "${keyValueArray["36"]};
                echo "46-55  : "${keyValueArray["46"]};
                echo "56-65  : "${keyValueArray["56"]};
                echo "66-75  : "${keyValueArray["66"]};
                echo "76-85  : "${keyValueArray["76"]};
                echo "86-95  : "${keyValueArray["86"]};
                echo "96-105 : "${keyValueArray["96"]};
                echo ">105   : "${keyValueArray["106"]};
                echo "None   : "${keyValueArray["None"]}
            fi
            ;;
        "daily" | "monthly" | "yearly" | "regions" | "districts" | "countries")
            case $COMMAND in
                "daily" ) dWidth=500; dKM="9999-99-99"; dKL="0-0-0"                   
                    ;;
                "monthly" ) dWidth=10000; dKM="9999"; dKL="0"                   
                    ;;
                "yearly" ) dWidth=100000; dKM="9999-99-99"; dKL="0-0-0"                   
                    ;;
                "regions" ) dWidth=10000; dKM="CZ09999999999"; dKL="0"                   
                    ;;
                "districts" ) dWidth=1000; dKM="CZ09999999999"; dKL="0"              
                    ;;
                "countries" ) dWidth=100; dKM="ZZZ"; dKL="0"                   
                    ;;
            esac

            if [[ $WIDTH -ne -1 ]]
            then
                max="None";
                for key in ${!keyValueArray[@]}; do
                    if [[ ${keyValueArray[$key]} -gt  ${keyValueArray[$max]} ]]
                    then
                        max=$key;
                    fi
                done
                numEqv=$((${keyValueArray[$max]}));
            else
                WIDTH=$dWidth;
                numEqv=$(($WIDTH*$WIDTH));
            fi

            keyLast=$dKL;
            for kkey in ${!keyValueArray[@]}; do
                keyMin=$dKM

                for key in ${!keyValueArray[@]}; do
                    if [[ $key < $keyMin && $key > $keyLast ]]
                    then
                        keyMin=$key;
                    fi
                done

                if [[ $keyMin = "CZ" ]]
                then 
                    keyLast=$keyMin;
                    continue;
                fi

                if [[ $keyMin = $dKM ]]
                then
                    if [[ ${keyValueArray["None"]} -ne 0 ]]
                    then
                        keyMin="None";
                    else
                        keyLast=$keyMin;
                        continue;
                    fi
                fi

                if [[ $s = 1 ]]
                then
                    echo -n ${keyMin}": "; WriteCharNTimes "#" $(($((${keyValueArray[$keyMin]}*$WIDTH))/$numEqv)); echo "";
                else
                    echo ${keyMin}": " ${keyValueArray[${keyMin}]};
                fi
                keyLast=$keyMin;
            done
            ;;
    esac
}




#
VariablesDeclaration() {
    keyValueArray["None"]=0
    case $COMMAND in
        "merge" )
            commandFunction=Merge;
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
            ;;
        "countries" )
            commandFunction=Countries;
            ;;
    esac
}




# Writes $1 $2 times
WriteCharNTimes() {
    for (( i = 0 ; i < $2 ; i++ )); do echo -n $1 
    done; 
}




Infected() {
    count=$($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'BEGIN {count = 0} NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1-\\2-\\3",1,$2)) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( /^\s*$/ || error != 0 || (a==1 && $2 < ta) || (b==1 && $2 > tb) || (g==1 && $4 != gender) ) { count++ } } END { print NR-1 - count}')
    INFECTED=$(($INFECTED+$count));     
}




Gender() {
    res=$($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'BEGIN {m = 0;z = 0} NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { if ($4 == "M") m++; else z++ } }
    END {
        print m","z;
    }')
    GENDERM=$((GENDERM + ${res%,*}))
    GENDERZ=$((GENDERZ + ${res##*,}))
}




Age() {
    for line in $($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print (length($3) != 0) ? $3 : "None";} }'); do
        keyValueArray[$line]=$((keyValueArray[$line]+1))
    done
}




Merge() {
    $1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print $1","$2","$3","$4","$5","$6","$7","$8","$9} }'
}




Daily() {
    for line in $($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print (length($2) != 0) ? $2 : "None";} }'); do
        keyValueArray[$line]=$((keyValueArray[$line]+1))
    done
}




Monthly() {
    for line in $($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print (length($2) != 0) ? $2 : "None";} }' | awk -F "-" '{ print (length($1)+length($2) != 0) ? $1"-"$2 : "None"; }'); do
        keyValueArray[$line]=$((keyValueArray[$line]+1))
    done
}




Yearly() {
    for line in $($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print (length($2) != 0) ? $2 : "None";} }' | awk -F "-" '{ print (length($1) != 0) ? $1 : "None"; }'); do
        keyValueArray[$line]=$((keyValueArray[$line]+1))
    done
}




Districts() {
    for line in $($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print (length($6) != 0) ? $6 : "None";} }'); do
        keyValueArray[$line]=$((keyValueArray[$line]+1))
    done
}




Regions() {
    for line in $($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print (length($5) != 0) ? $5 : "None";} }'); do
        keyValueArray[$line]=$((keyValueArray[$line]+1))
    done
}



Countries() {
    for line in $($1 | awk -F "," -v a=$a -v ta=$TIMEAFTER -v b=$b -v tb=$TIMEBEFORE -v g=$g -v gender=$GENDER 'NR != 1 { error=0; if ( ! /^\s*$/ && strftime("%Y-%m-%d",mktime(gensub(/^\s*(.{4})-(..)-(..)\s*$/,"\\1 \\2 \\3 0 0 0 ",1,$2))) != $2) { error++; print ("Invalid date: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( ! /^\s*$/ && $3 !~ /^\s*[0-9]*\s*$/) { error++; print ("Invalid age: "$1","$2","$3","$4","$5","$6","$7","$8","$9) > "/dev/stderr" }; if ( error == 0 && (a==0 || (a==1 && $2 >= ta)) && (b==0 || (b==1 && $2 <= tb)) && (g==0 || (g==1 && $4 == gender)) ) { print (length($8) != 0) ? $8 : "None";} }'); do
        keyValueArray[$line]=$((keyValueArray[$line]+1))
    done
}


# sets command to read file
SetCat() {
    if [[ $1 =~ .*\.bz2$ ]]
    then
        catt="bzcat $1"
    elif [[ $1 =~ .*\.gz$ ]]
    then
        catt="zcat $1"
    else
        catt="cat $1"
    fi
}







#===========================================================================
#   Main
#===========================================================================

Main() {
    c=0;a=0;b=0;s=0;g=0;d=0;r=0;
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


    catt="";
    if [[ ${#inputFileNames[@]} > 0 ]]
    then
        for input in ${inputFileNames[@]}; do
            SetCat $input;
            $commandFunction "$catt";
        done
    else
        catt="cat -"
        $commandFunction $catt;
    fi

    WriteOutput;
}

Main $@;