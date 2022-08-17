#!/bin/bash

# Aufruf festhalten
MYCOMMAND="[$$] Aufruf: $0 $*"

# Argumente auswerten
DEAMON=
SRC=

while (( $# ))
do
    case $1 in
        '-cmd' ) shift
                 CMD64="$1"
                 CMD=`echo "$1" | base64 --decode`
                 ;;

        '-url' ) shift
                 URL64="$1"
                 URL=`echo "$1" | base64 --decode`
                 ;;

        '-oid' ) shift
                 OID="$1"
                 ;;

        '-ep'  ) shift
                 EP64="$1"
                 EP=`echo "$1" | base64 --decode`
                 ;;

        '-srv' ) shift
                 SRV="$1"
                 ;;

        '-src' ) shift
                 SRC=`echo "$1" | base64 --decode`
                 ;;

        '-d'   ) DEAMON="1"
                 ;;
    esac

    shift
done

# Kein Deamon, dann nur Starten und die OID zurücksenden
if [ -z "${DEAMON}" ]
then
    #Logfile
    LOGDATE=`date +%Y-%m-%d`
    LOGFILE="`dirname $0`/log/x2Client-${SRV}-${LOGDATE}.log"
    LOGFILE64=`echo -n "${LOGFILE}" | base64`

    # Parameter ins Logfile schreiben
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` ${MYCOMMAND}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] Kommando: ${CMD}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] URL: ${URL}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] OID: ${OID}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] EP: ${EP}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] SRC: ${SRC}" >> ${LOGFILE}

    # die sh-Umgebung auswerten
    SRC_DEAMON=

    if [ ! -z "${SRC}" ]
    then
        SRC_DEAMON="-src `echo "${SRC}" | base64 -w 0`"
    fi

    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] Demonaufruf: $0 -d -url ${URL64} -oid ${OID} -ep ${EP64} -cmd ${CMD64} ${SRC_DEAMON}"  >> ${LOGFILE}

    # Deamon starten
    nohup $0 -d -url ${URL64} -oid ${OID} -ep ${EP64} -cmd ${CMD64} ${SRC_DEAMON} 1>>${LOGFILE} 2>&1 &
    DPID=`echo $!`
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] Deamon mit der PID ${DPID} gestartet" | tee -a ${LOGFILE}

    # Zurückmelden
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] senden an x2Deamon: wget -b -o /dev/null -O /dev/null ${URL}&nativeLogFile=${LOGFILE64}&nativeLogDate=${LOGDATE}" >> ${LOGFILE}
    wget -b -o /dev/null -O /dev/null "${URL}&nativeLogFile=${LOGFILE64}&nativeLogDate=${LOGDATE}"
else
    # Logfile
    LOGFILE="`dirname $0`/log/x2Client-$$.log"
    LOGFILE64=`echo -n "${LOGFILE}" | base64`

    # Parameter ins Logfile schreiben
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] Host: `hostname`" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] Kommando: ${CMD}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] URL: ${URL}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] OID: ${OID}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] EP: ${EP}" >> ${LOGFILE}
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] SRC: ${SRC}" >> ${LOGFILE}

    # in das Arbeitsverzeichnis wechseln
    if [ -d "${EP}" ]
    then
        cd ${EP}

        RET=0

        # Umgebungsvariablen sourcen
        if [ ! -z "${SRC}" ]
        then
            source ${SRC} 1>>${LOGFILE} 2>&1
            RET=$?
        fi

        # Kommando nur ausführen, wenn die Umgebung aufgebaut ist
        if [ ${RET} == 0 ]
        then
            # Commando im Hintergrund ausführen
            eval "${CMD} 1>>${LOGFILE} 2>&1 &"

            # die PID des Prozesses holen
            CPID=$!

            # Die PID an X2 und Logfile melden
            echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] CPID: ${CPID}" >> ${LOGFILE}
            echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] senden an x2Deamon: wget -b -o /dev/null -O /dev/null ${URL}&setPID=${CPID}" >> ${LOGFILE}
            wget -b -o /dev/null -O /dev/null "${URL}&setPID=${CPID}"

            # auf den Job warten und Returncode abgreifen
            wait ${CPID} || RET=$?
        fi
    else
        echo "Das Verzeichnis ${EP} existiert nicht" >> ${LOGFILE}
        RET=1
    fi

    echo "Returncode: ${RET}" >> ${LOGFILE}

    # zurückmelden
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` [$$] senden an x2Deamon: wget -b -o /tmp/wget -O /tmp/wget ${URL}&return=${RET}&logfile=${LOGFILE64}" >> ${LOGFILE}
    wget -b -o /tmp/wget -O /tmp/wget "${URL}&return=${RET}&logfile=${LOGFILE64}"
fi
