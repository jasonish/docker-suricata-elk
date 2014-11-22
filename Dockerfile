FROM centos:centos7

# Download our dependencies so they get cached early.
RUN cd /tmp && \
    curl -O http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.tar.gz && \
    curl -O http://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz && \
    curl -v -O -L -b "oraclelicense=accept-securebackup-cookie" \
      http://download.oracle.com/otn-pub/java/jdk/8u20-b26/jre-8u20-linux-x64.rpm

# Install EPEL.
RUN rpm -Uvh http://mirror.chpc.utah.edu/pub/epel/7/x86_64/e/epel-release-7-2.noarch.rpm

# The EPEL mirrorlist was broken when I wrote this Dockerfile.
RUN sed -i "s/#baseurl/baseurl/" /etc/yum.repos.d/epel.repo && \
    sed -i "s/mirrorlist/#mirrorlist/" /etc/yum.repos.d/epel.repo

RUN yum clean all && \
    yum -y update && \
    yum -y install \
	cronie \
	logrotate \
    	ed \
	tar \
	tcpdump \
	python-pip \
	nginx \
	git \
	gcc \
	automake \
	autoconf \
	make \
	libyaml-devel \
	libjansson-devel \
	nss-devel \
	nspr-devel \
	pcre-devel \
	file-devel \
	libpcap-devel \
	python-simplejson \
	zlib-devel \
	libtool \
	jansson-devel \
	lua-devel
RUN pip install supervisor

# Create a user to run non-root applications.
RUN useradd user

# Install the Oracle JRE.
RUN yum -y localinstall /tmp/jre-8u20-linux-x64.rpm

# Install Elastic Search.
RUN cd /opt && \
    tar zxvf /tmp/elasticsearch-1.3.2.tar.gz

# Install Logstash.
RUN cd /opt && \
    tar zxvf /tmp/logstash-1.4.2.tar.gz && \
    ln -s logstash-1.4.2 /opt/logstash

# Kibana
RUN cd /tmp && \
    curl \
      -O http://download.elasticsearch.org/kibana/kibana/kibana-3.1.1.tar.gz
RUN printf "/listen\ns/80/7777/\n.\nw\n" | \
      ed /etc/nginx/nginx.conf && \
    printf "/listen\n/root\nd\ni\n\troot /srv;\n.\nw\n" | \
      ed /etc/nginx/nginx.conf && \
    mkdir /srv/kibana && \
    cd /srv/kibana && tar zxvf /tmp/kibana-3.1.1.tar.gz --strip-components=1

# Extra Kibana templates.
RUN cd /usr/local/src && \
    git clone https://github.com/pevma/Suricata-Logstash-Templates.git && \
    cd Suricata-Logstash-Templates/Templates && \
    for template in *; do \
      cp $template /srv/kibana/app/dashboards/$template.json; \
    done && \
    cd /srv/kibana/app/dashboards && \
    curl -O http://www.inliniac.net/files/NetFlow.json

# EveBox.
RUN mkdir -p /usr/local/src/evebox && \
    cd /usr/local/src/evebox && \
    curl -L -o - https://github.com/jasonish/evebox/archive/cc3bf99a7023b5bda047944aead2de03c021ed57.tar.gz | tar zxf - --strip-components=1 && \
    cp -a app /srv/evebox

 # Build and install Suricata.
RUN cd /usr/local/src && \
    curl -O -L http://www.openinfosecfoundation.org/download/suricata-2.1beta2.tar.gz
RUN cd /usr/local/src && \
    tar zxvf suricata-2.1beta2.tar.gz && \
    cd suricata-2.1beta2 && \
    ./configure --disable-gccmarch-native && \
    make && \
    make install && \
    make install-full

# Copy in the Suricata logrotate configuration.
COPY image/etc/logrotate.d/suricata /etc/logrotate.d/suricata
RUN chmod 644 /etc/logrotate.d/suricata

# Make logrotate run hourly.
RUN mv /etc/cron.daily/logrotate /etc/cron.hourly/logrotate

# # Setup minimal web site.
# RUN cd /srv && \
#     curl -O \
#     https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css
RUN cd /srv && \
    curl -O \
    http://bootswatch.com/slate/bootstrap.min.css

# Install Elastic Search curator for optimizing and purging events.
RUN pip install elasticsearch-curator
COPY image/etc/cron.daily/elasticsearch-curator /etc/cron.daily/

# Link in files that are maintained outside of the container.
RUN ln -s /image/etc/supervisord.conf /etc/supervisord.conf && \
    ln -s /image/etc/supervisord.d /etc/supervisord.d && \
    ln -s /image/start.sh /start.sh && \
    ln -s /image/srv/index.html /srv/

# Some cleanup.
RUN yum --noplugins clean all && \
    rm -rf /var/log/* && \
    rm -rf /tmp/*

ENTRYPOINT ["/start.sh"]
