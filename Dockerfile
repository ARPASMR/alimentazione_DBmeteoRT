FROM debian:11-slim
# modalita' non interattiva
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
# cambio i timeout
RUN echo 'Acquire::http::Timeout "240";' >> /etc/apt/apt.conf.d/180Timeout
# installo gli aggiornamenti ed i pacchetti necessari (courtesy of https://github.com/occ-data/containers/blob/master/grads/Dockerfile et al.)
# tolti libc-dev zlib1g gcc gfortran g++ udunits-bin
ENV HTTPS_PROXY=https://meteo:%meteo2010@proxy2.arpa.local:8080/
ENV HTTP_PROXY=http://meteo:%meteo2010@proxy2.arpa.local:8080/
ENV https_proxy=https://meteo:%meteo2010@proxy2.arpa.local:8080/
ENV http_proxy=http://meteo:%meteo2010@proxy2.arpa.local:8080/
RUN apt-get update
RUN apt-get -y install curl git locales dnsutils openssh-client smbclient procps util-linux build-essential ncftp rsync  
RUN apt-get -y install nfs-common openssl libjpeg-dev libpng-dev 
RUN apt-get -y install libreadline-dev r-base r-base-dev
RUN apt-get install -y libmariadb-dev
RUN apt-get install -y libpq-dev
RUN R -e "install.packages('RMySQL', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('RPostgreSQL', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('lubridate', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('curl', repos = 'http://cran.us.r-project.org')"
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
RUN apt-get install -y ftp
RUN chmod a+x launcher.sh
RUN chmod a+x getcsv_from_ftp_rt.sh
RUN mkdir /usr/local/src/myscripts/data
CMD ["./launcher.sh"]
