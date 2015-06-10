FROM centos:centos7

RUN curl -v -o /tmp/elasticsearch.tar.gz -L \
    http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.4.tar.gz

RUN curl -v -o /tmp/jre.rpm -L -b "oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u20-b26/jre-8u20-linux-x64.rpm

RUN curl -L -v -o /tmp/kibana.tar.gz \
    http://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz

RUN curl -L -v -o /tmp/logstash.tar.gz \
    http://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz

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
	wget

RUN pip install supervisor

# Create a user to run non-root applications.
RUN useradd user

# Install the Oracle JRE.
RUN yum -y localinstall /tmp/jre.rpm

# Install Elastic Search.
RUN mkdir -p /opt/elasticsearch && \
    cd /opt/elasticsearch && \
    tar zxvf /tmp/elasticsearch.tar.gz --strip-components=1

# Install Logstash.
RUN mkdir -p /opt/logstash && \
    cd /opt/logstash && \
    tar zxvf /tmp/logstash.tar.gz --strip-components=1

RUN mkdir -p /srv/kibana && \
    cd /srv/kibana && \
    tar zxvf /tmp/kibana.tar.gz --strip-components=1

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
    curl -L -o - https://github.com/jasonish/evebox/archive/ac2061142c2abfe5f42d21ada0ef9096ecb5e02e.tar.gz | tar zxf - --strip-components=1 && \
    cp -a app /srv/evebox

RUN rpm -Uvh http://codemonkey.net/files/rpm/suricata-beta/el7/suricata-beta-release-el-7-1.el7.noarch.rpm
RUN yum -y install suricata

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

# Fixup Nginx to list on port 7777.
RUN printf "/listen\ns/80/7777/\n.\nw\n" | \
    ed /etc/nginx/nginx.conf && \
    printf "/listen\n/root\nd\ni\n\troot /srv;\n.\nw\n" | \
    ed /etc/nginx/nginx.conf

# Enable CORS and dynamic scripting in Elastic Search.
RUN echo "http.cors.enabled: true" >> /opt/elasticsearch/config/elasticsearch.yml
RUN echo "script.disable_dynamic: false" >> /opt/elasticsearch/config/elasticsearch.yml

# Some cleanup.
RUN yum --noplugins clean all && \
    rm -rf /var/log/* || true && \
    rm -rf /tmp/*

RUN rm -f /etc/supervisord.conf && \
    ln -s /image/etc/supervisord.conf /etc/supervisord.conf && \
    ln -s /image/start.sh /start.sh && \
    ln -s /image/srv/index.html /srv/index.html

ENTRYPOINT ["/start.sh"]
