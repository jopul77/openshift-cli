FROM jefferyb/openshift-alpine:latest

LABEL maintainer="Jeffery Bagirimvano"

ENV OC_VERSION=v3.11.0 \
    OC_TAG_SHA=0cbc58b \
    GLIBC_VERSION='2.28-r0' \
    BUILD_DEPS='tar gzip' \
    RUN_DEPS='curl ca-certificates gettext ansible git bash py-dnspython'

USER root

# https://github.com/sgerrand/alpine-pkg-glibc/
ADD https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
ADD https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk /tmp/glibc-${GLIBC_VERSION}.apk

RUN apk --no-cache add $BUILD_DEPS $RUN_DEPS && \
    apk --no-cache add py-jmespath --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ && \
    apk add /tmp/glibc-${GLIBC_VERSION}.apk && \
    curl -sLo /tmp/oc.tar.gz https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit.tar.gz && \
    tar xzvf /tmp/oc.tar.gz -C /tmp/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/oc /usr/local/bin/ && \
    mv /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit/kubectl /usr/local/bin/ && \
    rm -rf /tmp/oc.tar.gz /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_TAG_SHA}-linux-64bit /tmp/glibc-${GLIBC_VERSION}.apk && \
    mkdir -p /etc/ansible && \
    echo "[defaults]" > /etc/ansible/ansible.cfg && \
    echo "# human-readable stdout/stderr results display" >> /etc/ansible/ansible.cfg && \
    echo "stdout_callback = yaml" >> /etc/ansible/ansible.cfg && \
    echo "localhost     ansible_connection=local" >> /etc/ansible/hosts && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    apk del $BUILD_DEPS

USER 10001

CMD ["/usr/local/bin/oc"]

