FROM debian:11-slim
# modalita' non interattiva
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
# cambio i timeout
RUN echo 'Acquire::http::Timeout "240";' >> /etc/apt/apt.conf.d/180Timeout
# installo gli aggiornamenti ed i pacchetti di R necessari
RUN apt-get update
RUN apt-get -y install curl git locales dnsutils openssh-client smbclient procps util-linux build-essential ncftp rsync --fix-missing
RUN apt-get -y install openssl libjpeg-dev libpng-dev libreadline-dev libmariadb-dev libpq-dev vim r-base r-base-dev --fix-missing
RUN R -e "install.packages('DBI', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('RMySQL', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('RPostgreSQL', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('lubridate', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('curl', repos = 'http://cran.us.r-project.org')"
# filesystem
RUN mkdir -p /usr/local/src/myscripts/data
COPY ./aggiornamento_ftp_rt_k8s.R ./getcsv_from_ftp_rt_k8s.sh /usr/local/src/myscripts/
RUN chmod a+x -R /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
RUN apt-get install -y ftp
RUN apt-get install -y vim
RUN chmod a+x launcher.sh
RUN chmod a+x getcsv_from_ftp_rt.sh
RUN mkdir /usr/local/src/myscripts/data
CMD ["./launcher.sh"]
