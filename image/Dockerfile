FROM fedora:23

RUN dnf -y install https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.4.noarch.rpm && \
    dnf -y install https://download.elastic.co/logstash/logstash/packages/centos/logstash-1.5.6-1.noarch.rpm

RUN dnf -y install \
    	cronie \
	logrotate \
    	ed \
    	tar \
    	tcpdump \
    	python-pip \
    	nginx \
    	python-simplejson \
    	wget \
    	supervisor \
    	which \
    	tcpdump \
    	net-tools \
    	procps-ng \
	hostname \
	java-1.8.0-openjdk-headless \
	findutils \
    	dnf-plugins-core && \
    dnf -y copr enable jasonish/suricata-stable && \
    dnf -y install suricata

# Create a user to run non-root applications.
RUN useradd user

# Install Kibana 3.
RUN mkdir -p /srv/kibana && \
    cd /srv/kibana && \
    curl -o - -L -s http://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz | tar zxvf - --strip-components=1

# Pevma's Kibana Dashboards.
RUN cd /var/tmp && \
    curl -o - -L http://github.com/pevma/Suricata-Logstash-Templates/archive/master.tar.gz | tar zxvf - && \
    cd Suricata-Logstash-Templates-master/Templates && \
    for template in *; do \
      cp $template /srv/kibana/app/dashboards/$template.json; \
    done

# EveBox.
ENV EVEBOX_COMMIT be8389d4ad119a1ce984718297b94daa3b0c814d
RUN mkdir -p /usr/local/src/evebox && \
    cd /usr/local/src/evebox && \
    curl -L -o - http://github.com/jasonish/evebox/archive/${EVEBOX_COMMIT}.tar.gz | tar zxf - --strip-components=1 && \
    cp -a app /srv/evebox

# Setup minimal web site.
RUN cd /srv && \
    curl -O -L -# \
    http://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css

# Install idstools for rule updates.
RUN pip install --upgrade \
    http://github.com/jasonish/py-idstools/archive/master.zip

# Update the rules.
RUN idstools-rulecat --rules-dir=/etc/suricata/rules

# Install Elastic Search curator for optimizing and purging events.
RUN pip install elasticsearch-curator

# Fixup Nginx to list on port 7777.
RUN printf "\
/listen\n\
s/80/7777\n\
/listen\n\
s/80/7777\n\
/root\n\
d\n\
i\n\
\troot\t/srv;\n\
.\n\
w\n" | ed /etc/nginx/nginx.conf

# Enable CORS and dynamic scripting in Elastic Search.
RUN echo "http.cors.enabled: true" >> /etc/elasticsearch/elasticsearch.yml && \
    echo "script.disable_dynamic: false" >> /etc/elasticsearch/elasticsearch.yml

# Copy in files.
COPY /etc/supervisord.d /etc/supervisord.d
COPY /etc/logstash/conf.d /etc/logstash/conf.d
COPY /etc/logrotate.d /etc/logrotate.d
COPY /etc/cron.daily /etc/cron.daily
COPY /srv /srv
COPY /start.sh /start.sh
RUN mv /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml-default
COPY /etc/suricata /etc/suricata

# Fix permissions.
RUN chmod 644 /etc/logrotate.d/*

# Cleanup.
RUN dnf clean all && \
    rm -rf /var/tmp/* && \
    find /var/log -type f -exec rm -f {} \; && \
    rm -rf /tmp/* /tmp/.[A-Za-z]*

ENTRYPOINT ["/start.sh"]
