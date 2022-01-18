FROM frolvlad/alpine-glibc:latest

LABEL maintainer="Jeffery Bagirimvano"

ENV OC_VERSION=v3.11.0 \
    OC_TAG_SHA=0cbc58b \
    RUN_DEPS='curl ca-certificates gettext ansible git bash py3-dnspython tar gzip'\
ENV TRIVY_VERSION=0.22.0

# https://pkgs.alpinelinux.org/packages to search packages
RUN set -x && apk --no-cache add $BUILD_DEPS $RUN_DEPS && \
    apk --no-cache add py3-jmespath --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ && \
    curl -sLo /tmp/oc.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit.tar.gz && \
    tar xzvf /tmp/oc.tar.gz -C /tmp/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/oc /usr/local/bin/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/kubectl /usr/local/bin/ && \
    rm -rf /tmp/oc.tar.gz /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit && \
    mkdir -p /etc/ansible && \
    echo "[defaults]" > /etc/ansible/ansible.cfg && \
    echo "# human-readable stdout/stderr results display" >> /etc/ansible/ansible.cfg && \
    echo "stdout_callback = yaml" >> /etc/ansible/ansible.cfg
    
RUN wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
      tar zxvf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
      mv trivy /usr/local/bin
      
CMD ["/usr/local/bin/oc"]

