FROM ubuntu:14.04

MAINTAINER sahil.sharma@formcept.com

# Updating systsem and installing packages
RUN \
    apt-get update \
    && apt-get -y -u upgrade --no-install-recommends \
    && apt-get install -y --no-install-recommends \
      build-essential \
      software-properties-common \
      curl \
      wget \
      supervisor \
      libgconf2-4 \
      libfontconfig \
      nano \
      python \
      openssh-server \
      net-tools \
      iputils-ping \
      telnet \
      links \
      sshpass \
    && apt-get install -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installing Java1.7
RUN \
  echo "Adding webupd8team repository..."  && \
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list  && \
  echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list  && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886

RUN \
  echo "Updating packages..."  && \
  apt-get update  && \
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -f -y --force-yes

RUN \
  echo "Installing Java..."  && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections  && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes oracle-java7-installer oracle-java7-set-default

RUN \
  echo "Cleaning up..."  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

# Setting up SSH keys
RUN cd /root && ssh-keygen -t dsa -P '' -f "/root/.ssh/id_dsa" \
    && cat /root/.ssh/id_dsa.pub >> /root/.ssh/authorized_keys \
    && chmod 644 /root/.ssh/authorized_keys

# Daemon supervisord
RUN mkdir -p /var/log/supervisor
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Daemon SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/without-password/yes/g' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config \
    && echo '    StrictHostKeyChecking no' >> /etc/ssh/ssh_config \
    && echo 'SSHD: ALL' >> /etc/hosts.allow

#Download Grafana *.deb file
RUN cd /opt \
    && wget https://grafanarel.s3.amazonaws.com/builds/grafana_4.0.2-1481203731_amd64.deb \
    && dpkg -i /opt/grafana_4.0.2-1481203731_amd64.deb
    && rm /opt/grafana_4.0.2-1481203731_amd64.deb

# Daemon
CMD ["/usr/bin/supervisord"]
