FROM openjdk:8

LABEL Description="This image provides a base Android development environment for React Native may be used to run tests and distribute apps via fastlane."


# set default build arguments
ARG NODE_VERSION=10.x
ARG RUBY_VERSION=2.4.4
ENV WATCHMAN_VERSION=4.9.0

# Install Watchman
RUN apt-get update \
  && apt-get install -y python python-dev pkg-config libssl-dev autoconf automake libtool \
  && cd /tmp \
  && git clone https://github.com/facebook/watchman.git \
  && cd watchman \
  && git checkout v${WATCHMAN_VERSION} \
  && ./autogen.sh \
  && ./configure \
  && make \
  && make install \
  && cd $HOME \
  && rm -rf /tmp/watchman

# set default environment variables
ENV ANDROID_COMPILE_SDK="28" \
    ANDROID_BUILD_TOOLS="28.0.3" \
    ANDROID_SDK_TOOLS_REVISION="4333796" \
    ANDROID_HOME="/android-sdk-linux" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    LANGUAGE="en_US:en" \
    DEBIAN_FRONTEND=noninteractive
ENV PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

# install rvm
RUN apt-get update -q  && \
    apt-get install -qy curl ca-certificates gnupg build-essential --no-install-recommends  && \
    rm -rf /var/lib/apt/lists/*;

# https://github.com/inversepath/usbarmory-debian-base_image/issues/9
RUN mkdir ~/.gnupg
RUN echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

# install ruby dev
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s
RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm install ${RUBY_VERSION}-dev"

# Install system dependencies and fastlane
RUN apt update && \
    apt-get install -qq -y --no-install-recommends \
        apt-transport-https \
        curl \
        build-essential \
        file \
        git \
        openjdk-8-jre \
        gnupg2 \
        python \
        libcurl3-dev \
        openssh-client \
        unzip \
        libpthread-stubs0-dev \
        g++ \
        make \
        imagemagick \
        gcc && \
    rm -rf /var/lib/apt/lists/*;

# install fastlane
RUN /bin/bash -l -c "gem install fastlane bundler -N"

# install nodejs and yarn packages from nodesource and yarn apt sources
RUN echo "deb https://deb.nodesource.com/node_${NODE_VERSION} stretch main" > /etc/apt/sources.list.d/nodesource.list && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends nodejs yarn && \
    rm -rf /var/lib/apt/lists/*

# install firebase cli
RUN npm install -g firebase-tools

# install android sdk
RUN apt-get -qq update --yes && \
    apt-get -qq install --yes \
            gradle \
            wget \
            tar \
            unzip \
            lib32stdc++6 \
            lib32z1 usbutils \
            python3.5 \
	        python3-pip \
            locales && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 \
              -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    mkdir -p $HOME/.android && \
    echo 'count=0' > $HOME/.android/repositories.cfg && \
    wget --quiet --output-document=$HOME/android-sdk.zip \
        https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_REVISION}.zip && \
    mkdir -p $ANDROID_HOME && \
    unzip -qq $HOME/android-sdk.zip -d $ANDROID_HOME && \
    rm -rf $HOME/android-sdk.zip && \
    mkdir -p $ANDROID_HOME/licenses && \
    echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > $ANDROID_HOME/licenses/android-sdk-license && \
    echo "d56f5187479451eabf01fb78af6dfcb131a6481e" >> $ANDROID_HOME/licenses/android-sdk-license && \
    echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" >> $ANDROID_HOME/licenses/android-sdk-license && \
    echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license && \
    echo "601085b94cd77f0b54ff86406957099ebe79c4d6" > $ANDROID_HOME/licenses/android-googletv-license && \
    echo "33b6a2b64607f11b759f320ef9dff4ae5c47d97a" > $ANDROID_HOME/licenses/google-gdk-license && \
    echo "e9acab5b5fbb560a72cfaecce8946896ff6aab9d" > $ANDROID_HOME/licenses/mips-android-sysimage-license && \
    export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools" && \
    sdkmanager --update >/dev/null && \
    sdkmanager "tools" >/dev/null && \
    sdkmanager "platform-tools" >/dev/null && \
    sdkmanager "build-tools;$ANDROID_BUILD_TOOLS" >/dev/null && \
    sdkmanager "ndk-bundle" >/dev/null && \
    sdkmanager "platforms;android-$ANDROID_COMPILE_SDK" >/dev/null && \
    sdkmanager "extras;android;m2repository" >/dev/null && \
    sdkmanager "extras;google;google_play_services" >/dev/null && \
    sdkmanager "extras;google;m2repository" >/dev/null && \
    sdkmanager \
        "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" >/dev/null
