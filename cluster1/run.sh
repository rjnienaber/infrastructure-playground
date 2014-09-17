#!/bin/bash
set -e

#we set the users here because it's only at the point of running
#that we can specify a hostname for the docker command
#settings in rabbitmq are tied to the hostname
#change the hostname and your settings getting reset
/etc/init.d/rabbitmq-server start && rabbitmqctl add_user admin Rabbit123 && rabbitmqctl set_user_tags admin administrator && rabbitmqctl set_permissions -p / admin ".*" ".*" ".*" && rabbitmqctl delete_user guest
/etc/init.d/rabbitmq-server restart
tail -F /var/log/rabbitmq/rabbit@cluster1.log