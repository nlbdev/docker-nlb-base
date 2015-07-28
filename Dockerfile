FROM ubuntu:15.04

MAINTAINER Jostein Austvik Jacobsen

# Set working directory to home directory
WORKDIR /root/

# Install dependencies
RUN apt-get install -y software-properties-common
RUN sed -i.bak 's/main$/main universe/' /etc/apt/sources.list
RUN add-apt-repository -y ppa:cwchien/gradle
RUN locale-gen en_US en_US.UTF-8
RUN apt-get update && apt-get install -y wget unzip
RUN apt-get update && apt-get install -y openjdk-8-jdk
RUN apt-get update && apt-get install -y maven gradle mp3splt python3-pip
RUN pip3 install mutagen

# Install Calabash (XProc engine)
RUN wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.4-95/xmlcalabash-1.1.4-95.zip -O calabash.zip \
    && unzip calabash.zip \
    && mv xmlcalabash-* xmlcalabash
COPY resources/xmlcalabash/calabash xmlcalabash/calabash
ENV PATH $PATH:/root/xmlcalabash

# Install Saxon (XSLT engine)
RUN mkdir -p saxon/lib \
    && cd saxon/lib \
    && wget http://central.maven.org/maven2/net/sf/saxon/Saxon-HE/9.5.1-8/Saxon-HE-9.5.1-8.jar \
    && wget http://central.maven.org/maven2/xml-resolver/xml-resolver/1.2/xml-resolver-1.2.jar
COPY resources/saxon/saxon saxon/saxon
ENV PATH $PATH:/root/saxon

# Copy XML Catalog
COPY resources/xmlcatalog xmlcatalog

CMD if [ -e /tmp/script/run.sh ]; then /tmp/script/run.sh ; else echo "Script missing: /tmp/script/run.sh" ; fi
