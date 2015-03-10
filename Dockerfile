FROM centos:centos7

# Download our dependencies so they get cached early.
RUN cd /tmp && \
    curl -O http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.tar.gz && \
    curl -O http://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz && \
    curl -v -O -L -b "oraclelicense=accept-securebackup-cookie" \
      http://download.oracle.com/otn-pub/java/jdk/8u20-b26/jre-8u20-linux-x64.rpm

# Install EPEL.
RUN yum -y install epel-release

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
	python-simplejson \

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
      -O http://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz
RUN printf "/listen\ns/80/7777/\n.\nw\n" | \
      ed /etc/nginx/nginx.conf && \
    printf "/listen\n/root\nd\ni\n\troot /srv;\n.\nw\n" | \
      ed /etc/nginx/nginx.conf && \
    mkdir /srv/kibana && \
    cd /srv/kibana && tar zxvf /tmp/kibana-3.1.2.tar.gz --strip-components=1

# Extra Kibana templates.
RUN cd /usr/local/src && \
    curl -o - -L https://github.com/pevma/Suricata-Logstash-Templates/archive/master.tar.gz | tar zxvf - && \
    cd Suricata-Logstash-Templates-master/Templates && \
    for template in *; do \
      cp $template /srv/kibana/app/dashboards/$template.json; \
    done
RUN cd /srv/kibana/app/dashboards && \
    curl -O http://www.inliniac.net/files/NetFlow.json

# EveBox.
RUN mkdir -p /usr/local/src/evebox && \
    cd /usr/local/src/evebox && \
    curl -L -o - https://github.com/jasonish/evebox/archive/8b651b344681668d9e86ba052d30a8d56bede1df.tar.gz | tar zxf - --strip-components=1 && \
    cp -a app /srv/evebox

RUN rpm -Uvh http://codemonkey.net/files/rpm/suricata-beta/el7/suricata-beta-release-el-7-1.el7.noarch.rpm
RUN yum -y install suricata

RUN cd /etc/suricata && \
    curl -L -o - http://rules.emergingthreats.net/open/suricata-2.0/emerging.rules.tar.gz | tar zxvf -

# Copy in the Suricata logrotate configuration.
COPY image/etc/logrotate.d/suricata /etc/logrotate.d/suricata
RUN chmod 644 /etc/logrotate.d/suricata

# Make logrotate run hourly.
RUN mv /etc/cron.daily/logrotate /etc/cron.hourly/logrotate

# Setup minimal web site.
RUN cd /srv && \
    curl -O -L -# http://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css

# Install Elastic Search curator for optimizing and purging events.
RUN pip install elasticsearch-curator
COPY image/etc/cron.daily/elasticsearch-curator /etc/cron.daily/

# Link in files that are maintained outside of the container.
RUN rm -f /etc/supervisord.conf
RUN ln -s /image/etc/supervisord.conf /etc/supervisord.conf && \
    ln -s /image/etc/supervisord.d /etc/supervisord.d && \
    ln -s /image/start.sh /start.sh && \
    ln -s /image/srv/index.html /srv/

# Some cleanup.
RUN yum --noplugins clean all && \
    rm -rf /var/log/* && \
    rm -rf /tmp/*

ENTRYPOINT ["/start.sh"]
