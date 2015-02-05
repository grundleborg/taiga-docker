
FROM python:3
MAINTAINER Ivan Pedrazas "ipedrazas@gmail.com"
RUN apt-get -qq update

RUN apt-get install -y python-dev python-setuptools git-core locales

RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

ENV LC_ALL C.UTF-8

RUN (git clone https://github.com/taigaio/taiga-back.git taiga)

# Checkout the version we are going to build
RUN (cd /taiga && git checkout 1.5.0)

# docker needs to define the host database, use this file for
# any other settings you want to add/change

RUN pip install -r /taiga/requirements.txt

RUN (echo "alias ll='ls -atrhlF'" >> ~/.bashrc)

VOLUME ["/logs"]
VOLUME ["/mnt/settings"]

WORKDIR /taiga

EXPOSE 8000

CMD cp /mnt/settings/local.py /taiga/settings/local.py && python manage.py runserver 0.0.0.0:8000
