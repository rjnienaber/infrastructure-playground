FROM rjnienaber/rabbitmq:base
MAINTAINER Richard Nienaber <rjnienaber@gmail.com>

ADD run.sh /run.sh
RUN chmod +x /run.sh

#rabbitmq settings are tied to the hostname
#if the hostname changes, the settings disappear
#http://techblog.willshouse.com/2013/02/27/rabbitmq-users-disappear-settings-gone-after-reboot-restart/
RUN echo cluster2 > /etc/hostname
RUN echo NODENAME=rabbit@cluster2 > /etc/rabbitmq/rabbitmq-env.conf
# CMD /usr/lib/rabbitmq/bin/rabbitmq-server