# This image provides a jupyter notebook setup
FROM ubuntu:16.04

MAINTAINER "Prateek Gupta" <prateekgupta04@gmail.com>

EXPOSE 8080

# Add Cloudera apt repo for the hive jdbc driver
RUN apt-key adv --fetch-keys http://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh/archive.key && \
    echo 'deb [arch=amd64] http://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh xenial-cdh5 contrib' > /etc/apt/sources.list.d/cloudera.list

ENV LANG=C.UTF-8 
ENV PYTHON_VERSION=3.5 \
    PATH=$HOME/.local/bin/:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off
ENV SHELL /bin/bash

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        ssh \
        git \
        vim \
        wget \
        libnss-wrapper \
        gfortran \
        liblapack-dev \
        pkg-config \
        python3.5 \
        python3-pip \
        python3-setuptools \
        rsync \
        software-properties-common \
        unzip \
        python-virtualenv \
        libsasl2-dev \
        postgresql postgresql-contrib \
        libssl-dev libcurl4-openssl-dev libssl-dev && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# somehow the original installation of virtualenv is not found -> reinstall
# 
RUN pip3 install --upgrade pip
RUN pip3 install virtualenv --upgrade

ENV LANG=C.UTF-8

RUN virtualenv /opt/app-root -p /usr/bin/python3.5 

COPY run.sh /opt/app-root/src/
COPY requirements.txt /opt/app-root/src/
COPY jupyter_notebook_config.json /opt/app-root/src/.jupyter/jupyter_notebook_config.json
# remove the direct copying of etlmanager until the repos are merged
COPY etlmanager /opt/app-root/src/etlmanager

WORKDIR /opt/app-root/src/

# In order to drop the root user, we have to make some directories world
# writable as OpenShift default security model is to run the container under
# random UID.
RUN chown -R 1001:0 /opt/app-root && chmod -R ug+rwx /opt/app-root

# set user read/write capable R packages lib for install
# ENV R_LIBS=/opt/app-root/lib


RUN /bin/bash -c "source /opt/app-root/bin/activate && pip3 install -r requirements.txt && cd /opt/app-root/src/etlmanager && ls -la && pwd && pip3 install -e . && cd .."
RUN pip3 install jupyterlab && jupyter serverextension enable --py jupyterlab
# Set the default CMD to print the usage of the language image.


USER 1001

CMD ["./run.sh"]
