#!/bin/bash
set -e

/etc/init.d/rabbitmq-server start && rabbitmqctl add_user admin Rabbit123 && rabbitmqctl set_user_tags admin administrator && rabbitmqctl set_permissions -p / admin ".*" ".*" ".*" && rabbitmqctl delete_user guest
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@cluster1
rabbitmqctl start_app
tail -F /var/log/rabbitmq/rabbit@cluster2.log