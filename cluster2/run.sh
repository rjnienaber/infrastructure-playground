#!/bin/bash
set -e

#we set the users here because it's only at the point of running
#that we can specify a hostname for the docker command
#settings in rabbitmq are tied to the hostname
#change the hostname and your settings getting reset
/etc/init.d/rabbitmq-server start && rabbitmqctl add_user admin Rabbit123 && rabbitmqctl set_user_tags admin administrator && rabbitmqctl set_permissions -p / admin ".*" ".*" ".*" && rabbitmqctl delete_user guest
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@cluster1
rabbitmqctl start_app
rabbitmqctl set_cluster_name rabbitmq@cluster
tail -F /var/log/rabbitmq/rabbit@cluster2.log