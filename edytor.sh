#!/bin/bash

#konwersja sekund na h:m:s
function hour:min:sec() {
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
function isVideo() {
    local CHECK=$1
    if [ "${CHECK:0:2}" == "./" ]; then
        FILE="`pwd`/${CHECK:2}"
    fi
}
function outputFile() {
    OUT1="$TMP_DIR/output1.$EXTENTION"
    OUT2="$TMP_DIR/output2.$EXTENTION"
    FILE=$OUTPUT
    if [ "$OUTPUT" == "$OUT1" ]; then 
        OUTPUT=$OUT2
    else
        OUTPUT=$OUT1
    fi
}
FFMPEG_SILENT="-y -loglevel quiet"
FILE=$1
EXTENTION="mp4"
TMP_DIR="/home/krzysiu/PG/SO/lab/zadania/duzy_skrypt/.$$"
mkdir $TMP_DIR
OUTPUT="$TMP_DIR/output2.$EXTENTION"
#opcje menu
MENU=("Przycięcie" "Wstawianie" "Wstawianie ścieżki dzwiękowej" "Filtr" "Usuwanie powtarzających się klatek" "Export")
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
done
    isVideo $FILE

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
            if zenity --question --title "Wycięcie" --text "Przyciąć od $BEG do $END ?" --ok-label "Tak" --cancel-label "Nie"; then
                ffmpeg $FFMPEG_SILENT -ss $BEG -i $FILE -to $CUT -c copy $OUTPUT
                outputFile
            fi
        ;;
        "${MENU[1]}")
            LIST="$TMP_DIR/List.txt";
            touch $LIST
            echo "file '$FILE'" > $LIST
            while [ "TRUE" ]; do
                if zenity --list --title="Elementy do połączenia" --ok-label "Dodaj" --cancel-label "Połącz" --column="lp" --column="nazwa" `cat $LIST`; then
                    CONCAT_FILE=`zenity --file-selection --title="Wybór pliku do edycji"`
                    echo "file '$CONCAT_FILE'" >> $LIST
                else
                    break;
                fi
            done
            if zenity --question --title "Dopięcie" --text "Połączyć dane pliki?" --ok-label "Tak" --cancel-label "Nie"; then
                ffmpeg $FFMPEG_SILENT -f concat -safe 0 -i $LIST -c copy $OUTPUT
                outputFile
            fi
        ;;
        "${MENU[2]}")
            #Ścierzka dzwiękowa
        ;;
        "${MENU[3]}")
            #filtr
        ;;
        "${MENU[4]}")
            #klatki
        ;;
        "${MENU[5]}")
            OUTPUT=`zenity --entry --title="Export pliku " --text="Nazwa nowego pliu:" --entry-text "NowyPlik"`
            if [ "$OUTPUT" ] ; then
                OUTPUT="$OUTPUT.$EXTENTION"
                zenity --question --title "Export" --text "na pewno wyexportować?" --ok-label "Tak" --cancel-label "Nie"
                QUESTION_EXPORT=$?
                if [ $QUESTION_EXPORT -eq 0 ]; then
                    #sprawdzić czy istnieje
                    echo mv -f $FILE ./$OUTPUT
                    break;
                fi
            fi
        ;;
        *)
            break;
        ;;
    esac
done
rm -r $TMP_DIR
