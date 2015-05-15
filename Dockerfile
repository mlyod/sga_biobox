FROM debian:wheezy
MAINTAINER Michael Barton, mail@michaelbarton.me.uk

ENV PACKAGES zlib1g-dev libsparsehash-dev wget make automake g++ cmake ca-certificates


ENV BAM_TAR https://github.com/pezmaster31/bamtools/archive/v2.3.0.tar.gz
ENV BAM_DIR /tmp/bam

ENV SGA_TAR https://github.com/jts/sga/archive/v0.10.13.tar.gz
ENV SGA_DIR /tmp/sga

RUN echo "deb http://http.us.debian.org/debian testing main" > /etc/apt/sources.list
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ${PACKAGES}

ENV CONVERT https://github.com/bronze1man/yaml2json/raw/master/builds/linux_386/yaml2json
# download yaml2json and make it executable
RUN cd /usr/local/bin && wget --quiet ${CONVERT} && chmod 700 yaml2json

ENV JQ http://stedolan.github.io/jq/download/linux64/jq
# download jq and make it executable
RUN cd /usr/local/bin && wget --quiet ${JQ} && chmod 700 jq

RUN wget \
    --output-document /schema.yaml \
    --no-check-certificate \
https://raw.githubusercontent.com/bioboxes/rfc/master/container/short-read-assembler/input_schema.yaml

# Locations for biobox file validator
ENV VALIDATOR /bbx/validator/
ENV BASE_URL https://s3-us-west-1.amazonaws.com/bioboxes-tools/validate-biobox-file
ENV VERSION  0.x.y
RUN mkdir -p ${VALIDATOR}

# download the validate-biobox-file binary and extract it to the directory $VALIDATOR
RUN wget \
      --quiet \
      --output-document -\
      ${BASE_URL}/${VERSION}/validate-biobox-file.tar.xz \
    | tar xJf - \
      --directory ${VALIDATOR} \
      --strip-components=1

ENV PATH ${PATH}:${VALIDATOR}


RUN mkdir ${BAM_DIR}
RUN cd ${BAM_DIR} && \
    wget ${BAM_TAR} --no-check-certificate --output-document - \
    | tar xzf - --directory . --strip-components=1
RUN cd ${BAM_DIR} && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make

RUN mkdir ${SGA_DIR}
RUN cd ${SGA_DIR} && \
    wget ${SGA_TAR} --no-check-certificate --output-document - \
    | tar xzf - --directory . --strip-components=2 && \
    ./autogen.sh && \
    ./configure --with-bamtools=${BAM_DIR} && \
    make && \
    make install && \
    rm -rf ${SGA_DIR}

ADD run /usr/local/bin/
ADD assemble /usr/local/bin/
ADD Taskfile /

RUN chmod u+x /usr/local/bin/*

ENTRYPOINT ["assemble"]
