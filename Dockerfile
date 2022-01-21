
  
FROM frolvlad/alpine-glibc:latest

LABEL maintainer="Jeffery Bagirimvano"
USER root


ENV OC_VERSION=v3.11.0 \
    OC_TAG_SHA=0cbc58b \
    RUN_DEPS='curl ca-certificates gettext ansible git bash py3-dnspython tar gzip' \
    TRIVY_VERSION=0.22.0
    
ENV DOCKER_VERSION=1.13.1 \
    DOCKER_COMPOSE_VERSION=1.11.1 \
    ENTRYKIT_VERSION=0.4.0

# Install Docker, Docker Compose
RUN apk --update --no-cache \
        add curl device-mapper mkinitfs zsh e2fsprogs e2fsprogs-extra iptables && \
        curl https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
        mv /docker/* /bin/ && chmod +x /bin/docker* \
    && \
        apk add py-pip && \
        pip install docker-compose==${DOCKER_COMPOSE_VERSION}
        
VOLUME /var/run/docker.sock

RUN curl -L https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz | tar zxv
RUN mv ./entrykit /bin/entrykit
RUN chmod +x /bin/entrykit && entrykit --symlink

WORKDIR /src

RUN echo $'#!/bin/zsh \n\
/bin/docker daemon' > /bin/docker-daemon && chmod +x /bin/docker-daemon

RUN echo $'#!/bin/zsh \n\
docker info && \n\
/usr/bin/docker-compose pull && \n\
echo Cloning /var/lib/docker to /cached-graph... && \n\
ls -lah /var/lib/docker' > /bin/docker-compose-pull && chmod +x /bin/docker-compose-pull

ENV SWITCH_PULL="codep docker-daemon docker-compose-pull"
ENV SWITCH_SHELL=zsh
ENV CODEP_DAEMON=/bin/docker\ daemon
ENV CODEP_COMPOSE=/usr/bin/docker-compose\ up

# Include useful functions to start/stop docker daemon in garden-runc containers on Concourse CI
# Its usage would be something like: source /docker.lib.sh && start_docker "" "" "-g=$(pwd)/graph"
COPY docker-lib.sh /docker-lib.sh

# https://pkgs.alpinelinux.org/packages to search packages
RUN set -x && apk --no-cache add $BUILD_DEPS $RUN_DEPS && \
    apk --no-cache add py3-jmespath --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ && \
    curl -sLo /tmp/oc.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit.tar.gz && \
    tar xzvf /tmp/oc.tar.gz -C /tmp/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/oc /usr/local/bin/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/kubectl /usr/local/bin/ && \
    rm -rf /tmp/oc.tar.gz /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit && \
    mkdir -p /etc/ansible && \
    
    mkdir -p /opt/trivy/ && \
    wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz -O /opt/trivy/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    tar xvfz /opt/trivy/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz -C /opt/trivy/ && cp /opt/trivy/trivy /bin/ && chmod +x /bin/trivy &&\
    
    echo "[defaults]" > /etc/ansible/ansible.cfg && \
    echo "# human-readable stdout/stderr results display" >> /etc/ansible/ansible.cfg && \
    echo "stdout_callback = yaml" >> /etc/ansible/ansible.cfg \

RUN rc-update add docker default
ENTRYPOINT ["sh","/docker-lib.sh"]
