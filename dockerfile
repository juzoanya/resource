ARG DB_CERT_PASS
ARG SECRETS_USERNAME
ARG SECRETS_PASSWORD
ARG DB_HOST
ARG DEADLINE_VERSION
ARG DEADLINE_INSTALLER_BASE
ARG CERT_ORG
ARG CERT_OU

FROM ubuntu:20.04 AS base

ENV TZ=Europe/Berlin

WORKDIR /build

RUN apt-get update && apt-get install -y curl dos2unix python3 python3-pip git tzdata locales &&\
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime &&\
    dpkg-reconfigure --frontend noninteractive tzdata




FROM base AS db

ARG DB_CERT_PASS
ARG SECRETS_USERNAME
ARG SECRETS_PASSWORD
ARG DB_HOST
ARG DEADLINE_VERSION
ARG DEADLINE_INSTALLER_BASE
ARG CERT_ORG
ARG CERT_OU

RUN mkdir ~/keys

#Generate Certificates
RUN git clone https://github.com/ThinkboxSoftware/SSLGeneration.git &&\
    pip3 install pyopenssl==24.0.0

RUN python3 ./SSLGeneration/ssl_gen.py --ca --cert-org ${CERT_ORG} --cert-ou ${CERT_OU} --keys-dir ~/keys &&\
    python3 ./SSLGeneration/ssl_gen.py --server --cert-name ${DB_HOST} --alt-name localhost --alt-name 127.0.0.1 --keys-dir ~/keys &&\
    python3 ./SSLGeneration/ssl_gen.py --client --cert-name deadline-client --keys-dir ~/keys &&\
    python3 ./SSLGeneration/ssl_gen.py --pfx --cert-name deadline-client --keys-dir ~/keys --passphrase ${DB_CERT_PASS} &&\
    cat ~/keys/${DB_HOST}.crt ~/keys/${DB_HOST}.key > ~/keys/mongodb.pem


RUN mkdir /client_certs

#Install Database
RUN mkdir -p /opt/Thinkbox/DeadlineDatabase10/mongo/data &&\
 mkdir -p /opt/Thinkbox/DeadlineDatabase10/mongo/application &&\
 mkdir -p /opt/Thinkbox/DeadlineDatabase10/mongo/data/logs

COPY ./database_config/config.conf /opt/Thinkbox/DeadlineDatabase10/mongo/data/

RUN curl https://downloads.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-4.2.12.tgz -o mongodb-linux-x86_64-ubuntu1804-4.2.12.tgz 
RUN tar -xvf mongodb-linux-x86_64-ubuntu1804-4.2.12.tgz
RUN mv mongodb-linux-x86_64-ubuntu1804-4.2.12/bin /opt/Thinkbox/DeadlineDatabase10/mongo/application/
RUN rm mongodb-linux-x86_64-ubuntu1804-4.2.12.tgz && rm -rf mongodb-linux-x86_64-ubuntu1804-4.2.12

ADD ./database_entrypoint.sh .
RUN dos2unix ./database_entrypoint.sh && chmod u+x ./database_entrypoint.sh

ENTRYPOINT [ "./database_entrypoint.sh" ]



FROM base AS client

ARG DEADLINE_VERSION
ARG DEADLINE_INSTALLER_BASE

COPY ./Deadline-10.3.2.1-linux-installers.tar .
RUN pip install awscli
#RUN aws s3 cp --region us-west-2 --no-sign-request s3://thinkbox-installers/${DEADLINE_INSTALLER_BASE}-linux-installers.tar Deadline-${DEADLINE_VERSION}-linux-installers.tar
RUN tar -xvf Deadline-${DEADLINE_VERSION}-linux-installers.tar

RUN mkdir ~/certs


RUN apt-get install -y netcat lsb

ADD ./client_entrypoint.sh .
RUN dos2unix ./client_entrypoint.sh && chmod u+x ./client_entrypoint.sh


ENTRYPOINT [ "./client_entrypoint.sh" ]
