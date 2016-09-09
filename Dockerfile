FROM ubuntu:16.04

MAINTAINER Jostein Austvik Jacobsen

# Set working directory to /opt, which is where we will install things
WORKDIR /opt/

# Set up repositories
RUN apt-get update && apt-get install -y software-properties-common
RUN sed -i.bak 's/main$/main universe/' /etc/apt/sources.list
RUN add-apt-repository -y ppa:cwchien/gradle
RUN add-apt-repository -y ppa:openjdk-r/ppa

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

# Create a user with uid/gid 1000. This makes it possible to run GUIs from within the docker container on the host
# since 1000 is the default for most users on their host computers and not 0 which is the uid/gid for the root user
# in the docker container. Add the following flags when starting the container if you want to run GUIs: -e DISPLAY --net=host
# If your host user uses a uid or gid other than 1000, you can build an image for testing with another uid or gid
# by passing docker arguments like this: --build-arg user_uid=1001 --build-arg user_gid=1001
ARG user_name=user
ARG user_uid=1000
ARG user_gid=1000
RUN apt-get update && apt-get install -y sudo
RUN export uid=${user_uid} gid=${user_gid} && \
    mkdir -p /home/${user_name} && \
    echo "${user_name}:x:${uid}:${gid}:${user_name},,,:/home/${user_name}:/bin/bash" >> /etc/passwd && \
    echo "${user_name}:x:${uid}:" >> /etc/group && \
    echo "${user_name} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${user_name} && \
    chmod 0440 /etc/sudoers.d/${user_name} && \
    chown ${user_uid}:${user_gid} -R /home/${user_name}

# Install golang
RUN wget "https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz" \
    && tar -xvvf go*.tar.gz \
    && rm go*.tar.gz
ENV PATH $PATH:/opt/go/bin
ENV GOROOT /opt/go

# Install DAISY Pipeline 1
RUN svn checkout http://svn.code.sf.net/p/daisymfc/code/trunk@2810 daisymfc-code
RUN cd daisymfc-code/dmfc/ \
    && mkdir -p bin \
    && ant -f build-core.xml compile \
    && ant -f build-core.xml buildReleaseZip \
    && cd dist \
    && unzip pipeline-*.zip \
    && mv pipeline-*/ ../../../daisymfc \
    && cd ../../.. \
    && rm daisymfc-code -r
ENV PATH $PATH:/opt/daisymfc

# Install Calabash (XProc engine)
RUN wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.4-95/xmlcalabash-1.1.4-95.zip -O calabash.zip
RUN unzip calabash.zip \
    && mv xmlcalabash-* xmlcalabash \
    && rm calabash.zip
COPY resources/xmlcalabash/calabash xmlcalabash/calabash
ENV PATH $PATH:/opt/xmlcalabash

# Install Saxon (XSLT engine)
RUN mkdir -p saxon/lib \
    && cd saxon/lib \
    && wget http://central.maven.org/maven2/net/sf/saxon/Saxon-HE/9.5.1-8/Saxon-HE-9.5.1-8.jar \
    && wget http://central.maven.org/maven2/xml-resolver/xml-resolver/1.2/xml-resolver-1.2.jar
COPY resources/saxon/saxon saxon/saxon
ENV PATH $PATH:/opt/saxon

# Copy XML Catalog to users home directory
COPY resources/xmlcatalog /etc/opt/xmlcatalog
RUN chown -R user:user /etc/opt/xmlcatalog

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
RUN rm dp2-system test-server.retry -rf
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

# Install Filibuster (Brage) with dependencies

## Install dependencies
RUN apt-get update && apt-get install -y tcl8.6 tk8.6 tcllib tk-tile tcl-snack wavesurfer libsnack2-alsa mplayer pulseaudio alsa
RUN ln --symbolic /usr/bin/tclsh8.6 /usr/bin/tclsh8.4 # tclsh8.4 is hardcoded in filibuster
RUN usermod -a -G audio user

## Download Filibuster
RUN git clone https://gitlab.com/nlbdev/filibuster-brage.git
RUN cd filibuster-brage && git fetch -a && git checkout c696688c57ad0862ae0fb4db8cb274f8831a2d07

## Make changes to Filibuster so that it runs properly
RUN cp filibuster-brage/mari_config.tcl filibuster-brage/user_config.tcl
RUN cp filibuster-brage/Preproc/mari_config.pl filibuster-brage/Preproc/user_config.pl
RUN mv filibuster-brage/Preproc/lang/nob/Tagger/NLBtag filibuster-brage/Preproc/lang/nob/Tagger/NLBTag
RUN find filibuster-brage -type f | grep -v " " | grep "\.\(tcl\|pl\)$" | xargs sed -i 's/n151007/n160614/g'
RUN find filibuster-brage -type f | grep -v " " | grep "\.\(tcl\|pl\)$" | xargs sed -i 's/[A-Za-z]:\/.*filibuster[^\/]*\//\/opt\/filibuster-brage\//g'
RUN find filibuster-brage -type f | grep -v " " | grep "\.\(tcl\|pl\)$" | xargs sed -i 's/Tagger\/NLBtag/Tagger\/NLBTag/g'
RUN find filibuster-brage -type f | grep -v " " | grep "\.tcl$" | xargs sed -i 's/package require -exact/package require/g' # dont require exact package versions
RUN sed -i 's/package require sound.*/load snack\/64-bit\/libsound.so/g' filibuster-brage/narraFil2.tcl
RUN sed -i 's/\(puts stdout \[string length \[soundObject data -fileformat wav\]\]\)/#\1/' filibuster-brage/narraFil2.tcl
RUN sed -i 's/#set auto_path "C:\/wavesurfer\/src \$auto_path"/lappend auto_path \/usr\/share\/tcltk\/wavesurfer\//' filibuster-brage/filibuster.tcl
RUN mkdir -p filibuster-brage/Preproc/lang/nob/DB
RUN chmod +x filibuster-brage/filibuster.tcl

## Build lexicons
RUN cd filibuster-brage/Preproc \
    && sed -i 's/reload_lexica.*/reload_lexica = "1";/' user_config.pl \
    && USER=user perl nob_preproc.pl \
    && sed -i 's/reload_lexica.*/reload_lexica = "0";/' user_config.pl

## Set ownership to user
RUN chown -R ${user_name}:${user_name} filibuster-brage
RUN chmod 777 filibuster-brage

## Install as easy-to-use command invokable from anywhere
COPY resources/filibuster/filibuster filibuster-brage/filibuster
ENV PATH $PATH:/opt/filibuster-brage/

USER ${user_name}
WORKDIR /home/${user_name}/

CMD if [ -e /tmp/script/run.sh ]; then /tmp/script/run.sh ; else echo "Script missing: /tmp/script/run.sh" ; fi
