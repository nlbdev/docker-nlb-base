FROM ubuntu:15.04

MAINTAINER Jostein Austvik Jacobsen

# Set working directory to home directory
WORKDIR /root/

# Set up repositories
RUN apt-get install -y software-properties-common
RUN sed -i.bak 's/main$/main universe/' /etc/apt/sources.list
RUN add-apt-repository -y ppa:cwchien/gradle

# Set locale
RUN locale-gen en_GB en_GB.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL C.UTF-8

# Install dependencies
RUN apt-get update && apt-get install -y wget unzip
RUN apt-get update && apt-get install -y openjdk-7-jdk openjdk-8-jdk
RUN apt-get update && apt-get install -y maven gradle mp3splt python3-pip python3-yaml git subversion mercurial bzr ansible curl vim lame sox mp3info apcalc
RUN pip3 install mutagen slacker
ENV JAVA_7_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV JAVA_8_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Install golang
RUN wget "https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz" \
    && tar -xvvf go*.tar.gz \
    && rm go*.tar.gz
ENV PATH $PATH:/root/go/bin
ENV GOROOT /root/go

# Install DAISY Pipeline 1
RUN svn checkout http://svn.code.sf.net/p/daisymfc/code/trunk@2810 daisymfc-code
RUN cd ~/daisymfc-code/dmfc/ \
    && mkdir -p bin \
    && ant -f build-core.xml compile \
    && ant -f build-core.xml buildReleaseZip \
    && cd dist \
    && unzip pipeline-*.zip \
    && mv pipeline-*/ ~/daisymfc \
    && rm -r ~/daisymfc-code
    ENV PATH $PATH:/root/daisymfc

# Install Calabash (XProc engine)
RUN wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.4-95/xmlcalabash-1.1.4-95.zip -O calabash.zip
RUN unzip calabash.zip \
    && mv xmlcalabash-* xmlcalabash \
    && rm calabash.zip
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

# Install DAISY Pipeline 2 (Engine + Web UI)
# - Web UI not used, so stopping it's daemon.
# - Not adding Engine to PATH since it's installed as a daemon; control it with:
#     service pipeline2d {start|stop|status|restart|force-reload}
# - Install DAISY Pipeline 2 CLI separately since it's not installed by the snaekobbi/system script
# - the Pipeline 2 Engine will start on first invocation of "dp2"
RUN git clone https://github.com/snaekobbi/system.git dp2-system
RUN cd dp2-system && git checkout 1470e1268bc534eac164adde8eb39187867d96d8
RUN cd dp2-system && make
RUN cd dp2-system && ansible-playbook test-server.yml 2>&1 | grep "local .*ok.*changed.*unreachable.*failed=0"
RUN rm -rf dp2-system test-server.retry
RUN service pipeline2-webuid stop
RUN service pipeline2d stop
RUN wget "https://dl.dropboxusercontent.com/u/6370535/nordic-epub3-dtbook-migrator/epubcheck-adapter-with-dependencies/dependencies-1.8.1.zip"
RUN wget "https://dl.dropboxusercontent.com/u/6370535/nordic-epub3-dtbook-migrator/builds/`curl https://dl.dropboxusercontent.com/u/6370535/nordic-epub3-dtbook-migrator/current.txt`"
RUN unzip dependencies*.zip && mv -n modules/* /opt/daisy-pipeline2/modules/ && rm dependencies*zip
RUN mv -n nordic-*jar /opt/daisy-pipeline2/modules/
RUN wget "http://repo1.maven.org/maven2/org/daisy/pipeline/assembly/1.9.1/assembly-1.9.1-cli_all.deb"
RUN DEBIAN_FRONTEND=noninteractive dpkg -i assembly*cli*deb \
    && rm assembly*cli*deb \
    && echo '#!/bin/bash' > /usr/local/bin/dp2 \
    && echo 'service pipeline2d status >/dev/null' >> /usr/local/bin/dp2 \
    && echo 'if [[ "$?" -ne "0" ]] ; then service pipeline2d start ; fi' >> /usr/local/bin/dp2 \
    && echo 'while [[ 1 ]] ; do JAVA_HOME=$JAVA_7_HOME /opt/daisy-pipeline2-cli/dp2 help 2>&1 >/dev/null ; if [[ "$?" -eq "0" ]] ; then break ; fi ; done' >> /usr/local/bin/dp2 \
    && echo 'JAVA_HOME=$JAVA_7_HOME /opt/daisy-pipeline2-cli/dp2 "$@"' >> /usr/local/bin/dp2 \
    && chmod +x /usr/local/bin/dp2

CMD if [ -e /tmp/script/run.sh ]; then /tmp/script/run.sh ; else echo "Script missing: /tmp/script/run.sh" ; fi
