FROM openjdk:8

LABEL Description="This image provides a base Android development environment for React Native may be used to run tests and distribute apps via fastlane."


# set default build arguments
ARG SDK_VERSION=sdk-tools-linux-4333796.zip
ARG ANDROID_BUILD_VERSION=28
ARG ANDROID_TOOLS_VERSION=28.0.3
ARG BUCK_VERSION=2019.09.03.01
ARG NDK_VERSION=20
ARG NODE_VERSION=10.x
ARG WATCHMAN_VERSION=4.9.0
ARG RUBY_VERSION=2.4

# set default environment variables
ENV ADB_INSTALL_TIMEOUT=10
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV ANDROID_NDK=/opt/ndk/android-ndk-r$NDK_VERSION

ENV PATH=${ANDROID_NDK}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:/opt/buck/bin/:${PATH}

# install rvm
RUN apt-get update -q && \
    apt-get install -qy curl ca-certificates gnupg2 build-essential --no-install-recommends && apt-get clean

RUN gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN curl -sSL https://get.rvm.io | bash -s
RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm install 2.4.4"
# The entry point here is an initialization process, 
# it will be used as arguments for e.g.
# `docker run` command 
ENTRYPOINT ["/bin/bash", "-l", "-c"]

# Install system dependencies and fastlane
RUN apt update && apt-get install -qq -y --no-install-recommends \
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
        ruby-dev \
        imagemagick \
        gcc \
    && gem install fastlane bundler -N \
    && rm -rf /var/lib/apt/lists/*;

# install nodejs and yarn packages from nodesource and yarn apt sources
RUN echo "deb https://deb.nodesource.com/node_${NODE_VERSION} stretch main" > /etc/apt/sources.list.d/nodesource.list \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && apt-get update -qq \
    && apt-get install -qq -y --no-install-recommends nodejs yarn \
    && rm -rf /var/lib/apt/lists/*
    
# install firebase cli
RUN npm install -g firebase-tools

# download and unpack NDK
RUN curl -sS https://dl.google.com/android/repository/android-ndk-r$NDK_VERSION-linux-x86_64.zip -o /tmp/ndk.zip \
    && mkdir /opt/ndk \
    && unzip -q -d /opt/ndk /tmp/ndk.zip \
    && rm /tmp/ndk.zip

# download and install buck using debian package
RUN curl -sS -L https://github.com/facebook/buck/releases/download/v${BUCK_VERSION}/buck.${BUCK_VERSION}_all.deb -o /tmp/buck.deb \
    && dpkg -i /tmp/buck.deb \
    && rm /tmp/buck.deb

# Full reference at https://dl.google.com/android/repository/repository2-1.xml
# download and unpack android
RUN curl -sS https://dl.google.com/android/repository/${SDK_VERSION} -o /tmp/sdk.zip \
    && mkdir ${ANDROID_HOME} \
    && unzip -q -d ${ANDROID_HOME} /tmp/sdk.zip \
    && rm /tmp/sdk.zip \
    && yes | sdkmanager --licenses \
    && yes | sdkmanager "platform-tools" \
        "emulator" \
        "platforms;android-$ANDROID_BUILD_VERSION" \
        "build-tools;$ANDROID_TOOLS_VERSION" \
        "add-ons;addon-google_apis-google-23" \
        "system-images;android-19;google_apis;armeabi-v7a" \
        "extras;android;m2repository"

