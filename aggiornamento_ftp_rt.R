#############################################      
###  alimentazione tabelle RT             ###
###                                       ###
### MR                    31/07/2019      ###
### MR&MS dockerizzazione 20/01/2020      ###
###                                       ###
#############################################      

library(DBI)
library(RMySQL)

#_____________________________

file_log        <- 'aggiornamento_ftp_rt.log'
neverstop<-function(){
  cat("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:\n",file=file_log,append=T)
  quit()
}
options(show.error.messages=TRUE,error=neverstop)

cat ( "INSERIMENTO DATI METEO IN TABELLA TEMPO REALE", date()," \n\n" , file = file_log)

#___________________________________________________
#    COLLEGAMENTO AL DB
#___________________________________________________

cat("collegamento al DB...",file=file_log,append=T)
#definisco driver
drv<-dbDriver("MySQL")

conn<-try(dbConnect(drv, user=as.character(Sys.getenv("MYSQL_USR")), password=as.character(Sys.getenv("MYSQL_PWD")), dbname=as.character(Sys.getenv("MYSQL_DBNAME")), host=as.character(Sys.getenv("MYSQL_HOST"))))

#______________________________________________________
# INTERROGAZIONE DB PER ESTRARRE ANAGRAFICA 
#______________________________________________________
cat("interrogo DB per estrarre le info di anagrafica...",file=file_log,append=T)
q_anagrafica <- try( dbGetQuery(conn,"select IDsensore from A_Sensori, A_Stazioni where A_Stazioni.IDstazione=A_Sensori.IDstazione and IDrete in (1,4) and Storico='No'"),silent=TRUE )
#
if (inherits(q_anagrafica,"try-error")) {
  #cat(q_anagrafica,"\n",file=file_log,append=T)
  quit(status=1)
}

mysql_ID<-q_anagrafica$IDsensore

#___________________________________________________
#   PROCESSO FILE NUOVI DALLA DIRECTORY CSV_FTP 
#___________________________________________________
comando <- paste("ls *.csv",sep="")
nomefile <- try(readLines(pipe(comando)),silent=TRUE)
if (inherits(nomefile,"try-error")) {
  cat(nomefile,"\n",file=file_log,append=T)
  quit(status=1)
}

numerofiles<-length(nomefile)
cat("numero di files con dati da importare nell'archivio : ", numerofiles,"\n",file=file_log,append =T)

# ciclo sui files
cat("Inizio ciclo sui files\n",file=file_log,append=T)

i<-1
while( i <= length(nomefile) ){
  cat("\n ############## \n\n",i," sto elaborando il file : ",nomefile[i],"\n",file=file_log,append=T)
# chiudo connessioni precedenti
  closeAllConnections()
#___________________________________________________
# leggo info
#___________________________________________________
  cat("lettura\n",file=file_log,append=T)
  lettura<-NULL
  lettura <- try(read.csv(nomefile[i],
                  header=F, 
                  as.is=T,
                  fill=T,
                  na.string=c("","","-999","-999","-999"),
                  colClasses=c("integer","character","numeric","numeric","integer"),
                  col.names=c("ID","tempo","Variabile","codice_val","funzione")),silent=TRUE)
  if (inherits(lettura,"try-error")) {
    cat(lettura,"\n",file=file_log,append=T)
    cat("..............................................................................\n",file=file_log,append=T)
    cat(paste("Non e' possibile leggere il file ",nomefile[i]," passiamo al file successivo \n",sep=""),file=file_log,append=T)
    cat("..............................................................................\n",file=file_log,append=T)
    i<-i+1
    next 
  }
  sensore_nel_file <- NULL
  tempo            <- NULL
  variabile        <- NULL
  man              <- NULL
  funzione         <- NULL
#
  sensore_nel_file   <- lettura$ID
  tempo     <- as.POSIXct(strptime(lettura$tempo,format="%Y/%m/%d %H:%M"),"GMT")
# tempo_min <- min(tempo)
  variabile <- lettura$Variabile
  man       <- lettura$codice_val
  funzione  <- lettura$funzione
#  auto      <- lettura$codice_auto
# Controllo: File vuoto o anomalie strane?
  if ( (length(sensore_nel_file) == 0) |
       (length(tempo)==0)              |
       (length(variabile)==0)          |
       (length(man)==0)                |
       (length(funzione)==0) ) {
    cat ( " ATTENZIONE! il file e' (a) vuoto o (b) mal formattato ! Passo al file successivo \n", file= file_log, append=T)
    i<-i+1
    next 
  }
# Controllo su valori "NA" nelle misure: inizio 
#   (verra' ripetuto poi per verificare la consistenza nel passaggio dei vari array)
  if ( length(variabile[is.na(as.numeric(variabile))]) > 0 ) {
    aux_NA<-NULL
    aux_NA<-is.na(as.numeric(variabile)) 
    cat ( " ATTENZIONE! (tot) segnalo record/s nel file di input con NA nel campo \"Misura\" \n", file= file_log, append=T)
  }
# Controllo su valori "NA" in altri campi: inizio
  if ( length(sensore_nel_file[is.na(as.numeric(sensore_nel_file))]) > 0) {
    aux_NA<-NULL
    aux_NA<-is.na(as.numeric(sensore_nel_file)) 
    cat ( " ATTENZIONE! (tot) segnalo record/s nel file di input con NA nel campo \"IDsensore\" \n", file= file_log, append=T)
    cat ( " ATTENZIONE! questa e' una grave anomalia nel formato del file che puo' avere ripercussioni sul buon esito dell'applicazione \n", file= file_log, append=T)
  }
#
  if ( length(tempo[is.na(as.numeric(tempo))]) > 0) {
    aux_NA<-NULL
    aux_NA<-is.na(as.numeric(tempo)) 
    cat ( " ATTENZIONE! (tot) segnalo record/s nel file di input con NA nel campo \"tempo\" \n", file= file_log, append=T)
    cat ( " ATTENZIONE! questa e' una grave anomalia nel formato del file che puo' avere ripercussioni sul buon esito dell'applicazione \n", file= file_log, append=T)
  }
#
  if ( length(man[is.na(as.numeric(man))]) > 0) {
    aux_NA<-NULL
    aux_NA<-is.na(as.numeric(man)) 
    cat ( " ATTENZIONE! (tot) segnalo record/s nel file di input con NA nel campo \"flag\" \n", file= file_log, append=T)
    cat ( " ATTENZIONE! questa e' una grave anomalia nel formato del file che puo' avere ripercussioni sul buon esito dell'applicazione \n", file= file_log, append=T)
  }
  if ( length(funzione[is.na(as.numeric(funzione))]) > 0) {
    aux_NA<-NULL
    aux_NA<-is.na(as.numeric(funzione)) 
    cat ( " ATTENZIONE! (tot) segnalo record/s nel file di input con NA nel campo \"funzione\" \n", file= file_log, append=T)
    cat ( " ATTENZIONE! questa e' una grave anomalia nel formato del file che puo' avere ripercussioni sul buon esito dell'applicazione \n", file= file_log, append=T)
  }
#___________________________________________________
#  INSERISCO RECORD 
#___________________________________________________

# Controllo su valori "NA" nelle misure: inizio
#   (si ripete qui per verificare la consistenza nel passaggio dei vari array)
          if ( length(variabile[is.na(as.numeric(variabile))]) > 0) {
            aux_NA<-NULL
            aux_NA<-is.na(as.numeric(variabile)) 
            cat ( " ATTENZIONE! (chck1) segnalo record/s nel file di input con NA nel campo \"Misura\" \n", file= file_log, append=T)
#            cat ( rbind( "# ",Sensore[aux_NA],   " # ",
#                              format(Tempo[aux_NA],"%Y/%m/%d %H:%M","UTC"),  " # ",
#                              Variabile[aux_NA], " # ",
#                              Man[aux_NA],       " #\n"
#                       ) , file= file_log, append=T)
          }
# Controllo su valori "NA" nelle misure: fine
#_______________________________________________________
# DEFINISCO VARIABILI 
#______________________________________________________

          IDsensore            <- NULL 
          IDoperatore          <- NULL
          Data_e_ora           <- NULL 
          Misura               <- NULL 
          Flag_manuale_DBunico <- NULL 
          Data                 <- NULL 
#
          IDsensore            <- sensore_nel_file
          IDoperatore          <- funzione
          Data_e_ora           <- paste("'",tempo,"'",sep="")
          Misura               <- variabile
          Flag_manuale_DBunico <- man
          Data                 <- vector(                  length=length(IDsensore))
          Data[]               <- paste("'",as.character(Sys.time()),"'",sep="") 

# definizione data.frame 
          riga <- NULL
          riga <- data.frame( IDsensore            ,
                              IDoperatore          ,
                              Data_e_ora           ,
                              Misura               ,
                              Flag_manuale_DBunico ,
                              Data                 )

# impongo di essere vector e non factor (altrimenti ho Levels: 'P')
          riga$IDsensore       <- as.vector(riga$IDsensore)
          riga$Data_e_ora      <- as.vector(riga$Data_e_ora)

#______________________________________________________
# SEGNALO DATI MANCANTI 
#______________________________________________________
#
#print("segnalo mancanti")
          dati_mancanti <- which(is.na(riga$Misura) == T)
#print(dati_mancanti)
#      if(riga$Misura[dati_mancanti[]] != NA) quit(status=1)
          if(length(dati_mancanti)!=0) {
#            riga$Flag_automatica[dati_mancanti[]] <- "'M'"
# Controllo su valori "NA" nelle misure: inizio
#   (si ripete qui per verificare la consistenza nel passaggio dei vari array)
            cat ( " ATTENZIONE! (chck2) segnalo record/s nel file di input con NA nel campo \"Misura\" \n", file= file_log, append=T)
          }

          valori <-vector(length=length(riga$IDsensore))

          valori[] <- paste ( "(",
                              riga$IDsensore[]           , ","  , 
                              riga$IDoperatore[]          , ","  , 
                              riga$Data_e_ora[]          , ","  , 
                              riga$Misura[]              , ","  , 
                              riga$Flag_manuale_DBunico[], ","  , 
                              riga$Data[]                , ")" ,sep="")

          stringa<-NULL
          stringa <- toString(valori[])

#sostituisco eventuali NA
          stringa <- gsub("NA","NULL",stringa)

#_____________________________________________________
# SCRITTURA IN TABELLA 
#______________________________________________________
# preparo query e inserisco record
#print("inserimento righe in tavola recenti")
          nome_tavola_recente <- "M_RealTime" 
          cat("inserimento righe in tavola recenti: ", nome_tavola_recente,"\n", file=file_log, append=T)
          query_inserimento_riga<-paste("insert into ",nome_tavola_recente,
                                        " values ", stringa,
                                        " on duplicate key update Data=values(Data)", sep="")
          cat ( " query inserisci > ", query_inserimento_riga," \n", file= file_log, append=T)
          cat ( " effetua query inserimento \n", file= file_log, append=T)
          inserimento_riga <- try(dbGetQuery(conn,query_inserimento_riga),silent=TRUE)
          if (inherits(inserimento_riga,"try-error")) {
            cat(inserimento_riga,"\n",file=file_log,append=T)
            quit(status=1)
          }

############  CANCELLO RECORD RELATIVI A ISTANTI PRECEDENTI AI 10 GIORNI 
      query_cancella_riga<-paste("delete from ",nome_tavola_recente ," where Data_e_ora<'",Sys.Date()-10,"'", sep="")
      q_canc_riga <- try(dbGetQuery(conn, query_cancella_riga),silent=TRUE)
      if (inherits(q_canc_riga,"try-error")) {
        #cat(q_canc_riga,"\n",file=file_log,append=T)
        quit(status=1)
      }
############  CANCELLO EVENTUALI RECORD RELATIVI A ISTANTI SUCCESSIVI AL PRESENTE (NEL FUTURO) 
#      query_cancella_riga<-paste("delete from ",nome_tavola_recente ," where Data_e_ora>'",Sys.Date()+1,"'", sep="")
#      q_canc_riga <- try(dbGetQuery(conn, query_cancella_riga),silent=TRUE)
#      if (inherits(q_canc_riga,"try-error")) {
#        #cat(q_canc_riga,"\n",file=file_log,append=T)
#        quit(status=1)
#      }
###########
#__________________________________
#zippo file di dati inseriti 
  comando<-paste("gzip ", nomefile[i], sep=" ")
  #print(paste("@@@",comando,sep=""))
  rizzippo <-try(readLines(pipe(comando)),silent=TRUE)
  if (inherits(rizzippo,"try-error")) {
    cat(rizzippo,"\n",file=file_log,append=T)
    quit(status=1)
  }
#__________________________________

  i <- i + 1  #fine if sul file

} 

#___________________________________________________
#    DISCONNESSIONE DAL DB
#___________________________________________________

# chiudo db
cat ( "chiudo DB \n" , file = file_log , append = TRUE )
dbDisconnect(conn)
rm(conn)
dbUnloadDriver(drv)

cat ( "PROGRAMMA ESEGUITO CON SUCCESSO alle ", date()," \n" , file = file_log , append = TRUE )
quit(status=0)



