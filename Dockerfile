FROM centos:centos7.2.1511
MAINTAINER "Nick Griffin" <nicholas.griffin@accenture.com>

# Java Env Variables
# Go to: https://www.oracle.com/technetwork/java/javase/downloads/index.html
# Navigate to the middle of the page --> Server JRE -> then select linux64
# https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/server-jre-8u201-linux-x64.tar.gz
ENV JAVA_JRE_HASH=42970487e3af4f5aa5bca3f542482c60
ENV JAVA_JRE_NAME=8u201
ENV JAVA_VERSION=1.8.0_201
ENV JAVA_JRE_LASTNAME=b09
ENV JAVA_TARBALL=server-jre-${JAVA_JRE_NAME}-linux-x64.tar.gz
ENV JAVA_HOME=/opt/java/jdk${JAVA_VERSION}


# Swarm Env Variables (defaults)
ENV SWARM_MASTER=http://jenkins:8080/jenkins/
ENV SWARM_USER=jenkins
ENV SWARM_PASSWORD=jenkins

# Slave Env Variables
ENV SLAVE_NAME="Swarm_Slave"
ENV SLAVE_LABELS="aws ldap ansible php"
ENV SLAVE_MODE="exclusive"
ENV SLAVE_EXECUTORS=1
ENV SLAVE_DESCRIPTION="Core Jenkins Slave"

# Pre-requisites
RUN yum -y install epel-release
RUN yum install -y which \
    git \
    wget \
    tar \
    zip \
    unzip \
    openldap-clients \
    openssl \
    python-pip \
    libxslt \
    ant \
    ansible && \
    yum clean all 

RUN pip install awscli==1.10.19

# Since I removed the docker tag value for SLAVE_LABELS, these are no longer needed
#
## Docker versions Env Variables
#ENV DOCKER_ENGINE_VERSION=1.10.3-1.el7.centos
#ENV DOCKER_COMPOSE_VERSION=1.6.0
#ENV DOCKER_MACHINE_VERSION=v0.6.0
#
#
#RUN curl -fsSL https://get.docker.com/ | sed "s/docker-engine/docker-engine-${DOCKER_ENGINE_VERSION}/" | sh
#
#RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
#    chmod +x /usr/local/bin/docker-compose
#RUN curl -L https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}/docker-machine-`uname -s`-`uname -m` >/usr/local/bin/docker-machine && \
#    chmod +x /usr/local/bin/docker-machine

# Install Java
RUN echo wget -q --no-check-certificate --directory-prefix=/tmp \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
            http://download.oracle.com/otn-pub/java/jdk/${JAVA_JRE_NAME}-${JAVA_JRE_LASTNAME}/${JAVA_JRE_HASH}/${JAVA_TARBALL} 

RUN wget -q --no-check-certificate --directory-prefix=/tmp \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
            http://download.oracle.com/otn-pub/java/jdk/${JAVA_JRE_NAME}-${JAVA_JRE_LASTNAME}/${JAVA_JRE_HASH}/${JAVA_TARBALL} && \
          mkdir -p /opt/java && \
              tar -xzf /tmp/${JAVA_TARBALL} -C /opt/java/ && \
            alternatives --install /usr/bin/java java /opt/java/jdk${JAVA_VERSION}/bin/java 100 && \
                rm -rf /tmp/* && rm -rf /var/log/*

# Make Jenkins a slave by installing swarm-client
RUN curl -s -o /bin/swarm-client.jar -k http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/2.0/swarm-client-2.0-jar-with-dependencies.jar

# Start Swarm-Client
CMD java -jar /bin/swarm-client.jar -executors ${SLAVE_EXECUTORS} -description "${SLAVE_DESCRIPTION}" -master ${SWARM_MASTER} -username ${SWARM_USER} -password ${SWARM_PASSWORD} -name "${SLAVE_NAME}" -labels "${SLAVE_LABELS}" -mode ${SLAVE_MODE}
