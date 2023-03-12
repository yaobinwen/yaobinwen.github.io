ARG RUBY_VERSION=latest
FROM ruby:${RUBY_VERSION}
ARG USER_NAME=ywen
ARG USER_ID=1000
ARG GROUP_ID=1000

ARG LOCALE="en_US.UTF-8"
ARG LANGUAGE="en_US"
ARG TZ=Etc/UTC

RUN groupadd -g ${GROUP_ID} ${USER_NAME} && \
    useradd -r --create-home -u ${USER_ID} -g ${USER_NAME} ${USER_NAME}

RUN apt-get update

RUN apt-get -y install \
    netcat-openbsd \
    iproute2 \
    iputils-ping \
    tree \
    vim

# Switch to the non-root user.
USER ${USER_NAME}
