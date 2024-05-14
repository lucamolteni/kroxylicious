#
# Copyright Kroxylicious Authors.
#
# Licensed under the Apache Software License version 2.0, available at http://www.apache.org/licenses/LICENSE-2.0
#

FROM registry.access.redhat.com/ubi9/openjdk-17:1.15 AS builder

USER root
WORKDIR /opt/kroxylicious
COPY . .
RUN ./mvnw -q -B clean package -Pdist -Dquick
USER 185
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.2

ARG JAVA_VERSION=17
ARG TARGETOS
ARG TARGETARCH
ARG KROXYLICIOUS_VERSION

RUN microdnf -y update \
    && microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y java-${JAVA_VERSION}-openjdk-headless openssl shadow-utils \
    && microdnf clean all

ENV JAVA_HOME /usr/lib/jvm/jre-17

#####
# Add Tini
#####
ENV TINI_VERSION v0.19.0
ENV TINI_SHA256_AMD64=93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c
ENV TINI_SHA256_ARM64=07952557df20bfd2a95f9bef198b445e006171969499a1d361bd9e6f8e5e0e81
ENV TINI_SHA256_PPC64LE=3f658420974768e40810001a038c29d003728c5fe86da211cff5059e48cfdfde
ENV TINI_SHA256_S390X=931b70a182af879ca249ae9de87ef68423121b38d235c78997fafc680ceab32d
RUN set -ex; \
    if [[ "${TARGETOS}/${TARGETARCH}" = "linux/ppc64le" ]]; then \
        curl -s -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-ppc64le -o /usr/bin/tini; \
        echo "${TINI_SHA256_PPC64LE} */usr/bin/tini" | sha256sum -c; \
        chmod +x /usr/bin/tini; \
    elif [[ "${TARGETOS}/${TARGETARCH}" = "linux/arm64" ]]; then \
        curl -s -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-arm64 -o /usr/bin/tini; \
        echo "${TINI_SHA256_ARM64} */usr/bin/tini" | sha256sum -c; \
        chmod +x /usr/bin/tini; \
    elif [[ "${TARGETOS}/${TARGETARCH}" = "linux/s390x" ]]; then \
        curl -s -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-s390x -o /usr/bin/tini; \
        echo "${TINI_SHA256_S390X} */usr/bin/tini" | sha256sum -c; \
        chmod +x /usr/bin/tini; \
    else \
        curl -s -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini; \
        echo "${TINI_SHA256_AMD64} */usr/bin/tini" | sha256sum -c; \
        chmod +x /usr/bin/tini; \
    fi


# Async Profiler
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y tar gzip
RUN mkdir /usr/local/async-profiler/ &&\
      curl -L -o /usr/local/async-profiler/async-profiler.tar.gz https://github.com/async-profiler/async-profiler/releases/download/v3.0/async-profiler-3.0-linux-arm64.tar.gz &&\
      cd /usr/local/async-profiler/ &&\
      tar -xvzf async-profiler.tar.gz --strip-components=1  &&\
      rm -f /usr/local/async-profiler/async-profiler.tar.gz


COPY --from=builder /opt/kroxylicious/kroxylicious-app/target/kroxylicious-app-${KROXYLICIOUS_VERSION}-bin/kroxylicious-app-${KROXYLICIOUS_VERSION}/ /opt/kroxylicious/
ENTRYPOINT ["/usr/bin/tini", "--", "/opt/kroxylicious/bin/kroxylicious-start.sh" ]