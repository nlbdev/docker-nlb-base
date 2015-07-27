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
RUN apt-get update && apt-get install -y maven gradle
RUN apt-get update && apt-get install -y mp3splt

# Install Calabash (XProc engine) and Saxon (XSLT engine)
RUN wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.4-95/xmlcalabash-1.1.4-95.zip -O calabash.zip \
    && unzip calabash.zip \
    && mv xmlcalabash-* xmlcalabash
COPY resources/xmlcalabash/calabash xmlcalabash/calabash
COPY resources/xmlcalabash/saxon xmlcalabash/saxon
ENV PATH $PATH:/root/xmlcalabash

# Copy XML Catalog
COPY resources/xmlcatalog xmlcatalog

CMD mp3splt
