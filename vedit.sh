# Author           : Krzysztof Napiórkowski ( s191689@student.pg.edu.pl )
# Created On       : 2 April 2022
# Last Modified By : Krzysztof Napiórkowski ( s191689@student.pg.edu.pl )
# Last Modified On : 2 April 2022 
# Version          : 1.1
#
# Description      :
# simple video editor based on ffmpeg multimedia converter [ffmpeg.org]
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

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
#upewnianie się że FILE jest plikiem wideo
function isVideo() {
    local CHECK=$1
    if ! [ "$CHECK" ]; then
        return 1;
    fi
    if [ "${CHECK:0:2}" == "./" ]; then
        FILE="`pwd`/${CHECK:2}"
    fi

    local FILE_TYPE=`file -b $CHECK | grep "Media"`
    if [ "$FILE_TYPE" ]; then
        return 0
    else
        return 1
    fi
}
function isAudio() {
    local CHECK=$1
    local FILE_TYPE=`file -b $CHECK | grep "Audio"`
    if [ "$FILE_TYPE" ]; then
        return 0
    else
        return 1
    fi
}
#zmiana pliku tymczasowego aby nie wykonywać operacji na pliku aktualnie używanym
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
function createTmpDir() {
    [ ! -d $SH_DIR ] && mkdir $SH_DIR
    mkdir $TMP_DIR
}
function extention() {
    local FILE=$1
    echo `ls $FILE | rev | cut -d '.' -f 1 | rev`
}
#zmienne
FFMPEG_SILENT="-y -loglevel quiet"
FILE=$1
SH_DIR="`pwd`/.tmp"
TMP_DIR="$SH_DIR/.$$"
MENU=("Przycięcie" "Wstawianie" "Wstawianie ścieżki dzwiękowej" "czarno-biały filtr" "Podgląd aktualnego pliku" "Cofnij ostatnią zmianę" "Export")



while getopts hvf:q OPT; do
    case $OPT in
        h) 
            echo "usage: vedit.sh [optional_input_file]"
            echo "options:"
            echo "-h    -- print basic options"
            echo "-v    -- print script and ffmpeg versions"
        ;;
        v) 
            echo "vedit 1.1 2022"
            echo "ffmpeg version 4.4.1-3ubuntu5 Copyright (c) 2000-2021 the FFmpeg developers"
            echo "Author: Krzysztof Napiórkowski  s191689@student.pg.edu.pl"
        ;;
    esac
    exit
done

#Wybieranie pliku po uruchomieniu
until isVideo $FILE; do
    if [ "$FILE" ]; then
        zenity --notification --window-icon="error" --text="proszę wybrać plik wideo"
    fi
    FILE=`zenity --file-selection --title="Wybór pliku do edycji"`
    if [ $? -eq 1 ]; then
        exit
    fi
done

EXTENTION=$(extention $FILE)
OUTPUT="$TMP_DIR/output2.$EXTENTION"

createTmpDir

until [ "" ]; do
    COMMAND=`zenity --list --column=Menu "${MENU[@]}"`
    case $COMMAND in
        "${MENU[0]}") #przycięcie
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
        "${MENU[1]}") #łączenia
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
        "${MENU[2]}") #ścieżka dzwiękowa
            AUDIO=`zenity --file-selection --title="Wybór pliku"`
            until isAudio $AUDIO; do
                zenity --notification --window-icon="error" --text="proszę wybrać plik audio"
                AUDIO=`zenity --file-selection --title="Wybór pliku"`
            done
            if zenity --question --title "ścieżka" --text "Zastąpić obecną ścierzkę?" --ok-label "Tak" --cancel-label "Nie"; then
                REPLACE=0
            else
                REPLACE=1
            fi

            if zenity --question --title "ścieżka" --text "Dodać ścierzkę dzwiękową?" --ok-label "Tak" --cancel-label "Nie"; then
                if [ $REPLACE -eq 0 ]; then
                    ffmpeg $FFMPEG_SILENT -i $FILE -i $AUDIO -map 0:v -map 1:a -c:v copy -shortest $OUTPUT
                else
                    ffmpeg $FFMPEG_SILENT -i $FILE -i $AUDIO -filter_complex "[0:a:0][1:a:0]amerge=inputs=2[audio]" -map 0:v -map "[audio]" -c:v copy -ac 2 -shortest $OUTPUT
                fi
                outputFile
            fi
        ;;
        "${MENU[3]}") #czarno-biały filtr
            if zenity --question --title "klatki" --text "Usunąć powtarzające się klatki? Operacja ta usunie aktualną ścierzkę dzwiękową" --ok-label "Tak" --cancel-label "Nie"; then
                ffmpeg $FFMPEG_SILENT -i $FILE -vf hue=s=0 $OUTPUT
                outputFile
            fi
        ;;
        "${MENU[4]}") #podgląd
            ffplay $FILE
        ;;
        "${MENU[5]}") #cofnięcie ostatniej zmiany
            if zenity --question --title "cofnięcie zmiany" --text "cofnąć ostatnią zmianę? możliwe jest cofnięcie tylko ostatniej zmiany." --ok-label "Tak" --cancel-label "Nie"; then
                OUTPUT=$FILE
                outputFile
            fi
        ;;
        "${MENU[6]}") #export
            OUTPUT=`zenity --entry --title="Export pliku " --text="Nazwa nowego pliu:" --entry-text "NowyPlik"`
            if [ "$OUTPUT" ] ; then
                OUTPUT="$OUTPUT.$EXTENTION"
                zenity --question --title "Export" --text "na pewno wyexportować?" --ok-label "Tak" --cancel-label "Nie"
                QUESTION_EXPORT=$?
                if [ $QUESTION_EXPORT -eq 0 ]; then
                    if [ "$OUTPUT" ]; then
                        mv -f $FILE ./$OUTPUT
                        break;
                    else
                    zenity --notification --window-icon="error" --text="nazwa pliku wyjściowego nie może być pusta"
                    fi
                fi
            fi
        ;;
        *)
            break;
        ;;
    esac
done
rm -r $SH_DIR
