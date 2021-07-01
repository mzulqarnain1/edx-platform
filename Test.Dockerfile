FROM ubuntu:focal as base

# Install system requirements
RUN apt-get update && \
    # Global requirements
    DEBIAN_FRONTEND=noninteractive apt-get install --yes \
    build-essential \
    curl \
    # If we don't need gcc, we should remove it.
    g++ \
    gcc \
    git \
    git-core \
    language-pack-en \
    libfreetype6-dev \
    libmysqlclient-dev \
    libssl-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libxslt1-dev \
    swig \
    # openedx requirements
    gettext \
    gfortran \
    gnupg \
    graphviz \
    libffi-dev \
    libfreetype6-dev \
    libgeos-dev \
    libgraphviz-dev \
    libjpeg8-dev \
    liblapack-dev \
    libpng-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libxslt1-dev \
    iputils-ping \
    # lynx: Required by https://github.com/edx/edx-platform/blob/b489a4ecb122/openedx/core/lib/html_to_text.py#L16
    lynx \
    ntp \
    packagekit-gtk3-module \
    xvfb \
    wget \
    pkg-config \
    python3-dev \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /edx/app/edxapp/edx-platform

ENV PATH /edx/app/edxapp/nodeenv/bin:${PATH}
ENV PATH ./node_modules/.bin:${PATH}
ENV CONFIG_ROOT /edx/etc/
ENV PATH /edx/app/edxapp/edx-platform/bin:${PATH}
ENV SETTINGS production
RUN mkdir -p /edx/etc/

ENV VIRTUAL_ENV=/edx/app/edxapp/venvs/edxapp
RUN python3.8 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python requirements
COPY setup.py setup.py
COPY common common
COPY openedx openedx
COPY lms lms
COPY cms cms
COPY requirements/pip.txt requirements/pip.txt
COPY requirements/edx/testing.txt requirements/edx/testing.txt
RUN pip install -r requirements/pip.txt
RUN pip install -r requirements/edx/testing.txt
RUN pip install pytest-split

COPY lms/envs/bok_choy.yml /edx/etc/lms.yml
COPY lms/envs/bok_choy.yml /edx/etc/studio.yml

ENV LMS_CFG /edx/etc/lms.yml
ENV STUDIO_CFG /edx/etc/studio.yml

# Copy over remaining code.
# We do this as late as possible so that small changes to the repo don't bust
# the requirements cache.
COPY . .

RUN mkdir -p test_root/log/
