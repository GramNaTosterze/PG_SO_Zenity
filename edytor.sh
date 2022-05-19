#!/bin/bash

#konwersja sekund na h:m:s
hour:min:sec() {
    local COPY=$1
    local HOUR=0
    local MIN=0
    local SEC=0
    while [ "$COPY" -gt  "3600" ]; do
        ((HOUR++))
        ((COPY-=3600))
    done
    while [ "$COPY" -gt "60" ]; do
        ((MIN++))
        ((COPY-=60))
    done
    SEC=$COPY
    echo "$HOUR:$MIN:$SEC";
}
#upewnianie się że FILE jest plikiem wideo //do zrobienia
isVideo() {
    local CHECK=$1
}
FILE=$1
OUTPUT=$2
#opcje menu
MENU=("Przycięcie" "Wstawianie" "Wstawianie ścieżki dzwiękowej" "Filtr" "Usuwanie powtarzających się klatek")
while getopts hvf:q OPT; do
    case $OPT in
        h) 
            echo "prosty edytor plików wideo na podstawie ffmpeg"
        ;;
        v) 
            echo "szczerze nie liczona"
        ;;
    esac
done

#Wybieranie pliku po uruchomieniu
while ! [ $FILE ]; do
    FILE=`zenity --file-selection --title="Wybór pliku do edycji"`
    isVideo $FILE
done

until [ "" ]; do
    COMMAND=`zenity --list --column=Menu "${MENU[@]}" $DIMENTIONS`
    case $COMMAND in
        "${MENU[0]}")
            VIDEO_LENGHT=`ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $FILE`
            VIDEO_LENGHT=`awk  "BEGIN { print sprintf(\"%.0f\", $VIDEO_LENGHT) }"`
            BEG=`zenity --scale --text="Wybór początek" --value=0 --min-value=0 --max-value=$VIDEO_LENGHT`
            END=`zenity --scale --text="Wybór koniec" --value=$VIDEO_LENGHT --min-value=$BEG --max-value=$VIDEO_LENGHT`
            CUT=$(hour:min:sec $((END-BEG)))
            BEG=$(hour:min:sec $BEG)
            END=$(hour:min:sec $END)
            zenity --question --title "Akcja" --text "Przyciąć od $BEG do $END ?" --ok-label "Tak" --cancel-label "Nie"
            QUESTION_CUT=$?
            if [ $QUESTION_CUT -eq 0 ]; then
                ffmpeg -ss $BEG -i $FILE -ss $CUT -t $CUT -c copy Output.mp4
            fi
        ;;
        "${MENU[1]}")
            #Wstawianie
        ;;
        "${MENU[2]}")
            #Ścierzka dzwiękowa
        ;;
        *)
            break;
        ;;
    esac
done