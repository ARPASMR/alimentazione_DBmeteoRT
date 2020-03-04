#!/bin/bash
#===============================================================================
#  alimentazione delle tabelle ai 10' del DBmeteo
#  scarica i files .csv con i dati dal server ftp.
#
# 2019/07/31  MS & MR - Codice originale
# 2020/01/20  MR - dockerizzazione 
#------------------------------------------------------------------------------

DIRDATA=data
FTP=/usr/bin/ftp
SUBS="---> QUIT"
FTP_LOG=ftp_rt.log
ERRE=/usr/bin/R
AGGIORNAMENTO_FTP=aggiornamento_ftp_rt.R
AGGIORNAMENTO_FTP_LOG=aggiornamento_ftp_test.log
# Info di Log
echo "#~### getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" ###~#"
echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > scarico files .csv dall'ftp server di ARPA Lombardia"
echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" >       ftp-server: "$FTP_SERV
echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" >          ftp-usr: "$FTP_USR
echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > directory remota: "$FTP_DIR
echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > directory locale: "$DIRDATA
NUM=0
# ----
cd $DIRDATA
# Scarica i dati e salvali sul PC locale
rm -f $FTP_LOG
NUM=`ls -1  TestRT*.csv | wc -l`
ncftpget -u $FTP_USR -p $FTP_PWD -d $FTP_LOG -t 60 -DD ftp://$FTP_SERV/$FTP_DIR/TestRT*.csv
#$FTP -n -v -d <<FINE1 > $FTP_LOG
#open $FTP_SERV
#quote user $FTP_USR
#quote pass $FTP_PWD
#cd $FTP_DIR
#prompt
#mget TestRT_*.csv
#mdelete TestRT_*.csv
#bye
#FINE1
if [ "$?" -ne 0 ]
  then
    echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > ERRORE FTP"
#    exit 1
#fi
#FLAG=0
#{ while read RIGA
#  do
#    if [ "$RIGA" = "$SUBS" ]
#    then
#      FLAG=1
#    fi
#  done
#} < $FTP_LOG
#if [ "$FLAG" -ne 1 ]
#then
#  echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > ERRORE di connessione con ftp-server!"
    echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > Ulteriori dettagli dal file di log di ftp:"
    echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > INIZIO: "
   { while read RIGA
     do
       echo "ftp LOG  > "$RIGA
     done
   } < $FTP_LOG
   echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > FINE. "
   exit 1
fi
#
NUM1=`ls -1  TestRT*.csv | wc -l`
NUM2=$(( NUM1-NUM ))
echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > numero di files scaricati dall'FTP server = "$NUM2
echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > numero di files presenti nella directory  = "$NUM1

# Aggiornamento archivio MySQL
if [ "$NUM1" -gt 0 ]
then
  echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > Avvio applicativo R che aggiorna l'archivio MySQL"
  echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > vvvvvvvvv~vvvvv~vvvvvvv~vvvvvv~~vvvv~~v~vvvvvvvvv"
  $ERRE --vanilla < ../$AGGIORNAMENTO_FTP
  if [ "$?" -ne 0 ]
  then
    echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > ERRORE nell'esecuzione dell'istruzione :"
    echo "getcsv_from_ftp_rt.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > "$ERRE" --save --no-restore < "$AGGIORNAMENTO_FTP
  fi
    echo "getcsv_from_ftp_test.sh "`date  '+%Y/%m/%d %H:%M:%S'`" > ^^^^~^^^^^^^^^^^^^^^^^^^^^~^^^^^^^^^^^^^^^^^^^^~^"
else
    echo "nessun file presente in ftp REM"
fi


# pulizia della directory dei file
 find . -type f -name 'TestRT*.csv.gz' -mtime 1 -exec rm {} \;

# Fine con successo
exit 0
