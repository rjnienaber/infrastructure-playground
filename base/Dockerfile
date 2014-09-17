FROM tutum/debian:squeeze
MAINTAINER Richard Nienaber <rjnienaber@gmail.com>
ADD rabbitmq-signing-key-public.asc /tmp/rabbitmq-signing-key-public.asc
RUN echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list
RUN apt-key add /tmp/rabbitmq-signing-key-public.asc
RUN apt-get update
RUN apt-get install vim tree lsof net-tools wget curl moreutils rabbitmq-server -y
RUN rabbitmq-plugins enable rabbitmq_management
RUN rabbitmq-plugins enable rabbitmq_shovel
RUN rabbitmq-plugins enable rabbitmq_shovel_management
ADD .erlang.cookie /var/lib/rabbitmq/.erlang.cookie
RUN chmod 400 /var/lib/rabbitmq/.erlang.cookie
RUN chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
EXPOSE 5672 15672 4369 25672