#!/bin/bash
set -e

/etc/init.d/rabbitmq-server start && rabbitmqctl add_user admin Rabbit123 && rabbitmqctl set_user_tags admin administrator && rabbitmqctl set_permissions -p / admin ".*" ".*" ".*" && rabbitmqctl delete_user guest
/etc/init.d/rabbitmq-server restart
tail -F /var/log/rabbitmq/rabbit@cluster3.log