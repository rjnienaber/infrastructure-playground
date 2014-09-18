start_containers = %Q{docker rm `docker ps -a -q`
docker images -a | grep '<none>' | cut -d ' ' -f 31 | xargs docker rmi

docker run -d -h cluster1 -p 15672:15672 -p 5672:5672 --name cluster1 rjnienaber/rabbitmq:cluster1
docker run -d -h cluster3 -p 15674:15672 -p 5674:5672 --name cluster3 rjnienaber/rabbitmq:cluster3

#wait for the first machine to start up
sleep 10
docker run -d -h cluster2 -p 15673:15672 -p 5673:5672 --link cluster1:cluster1 --name cluster2 rjnienaber/rabbitmq:cluster2
}

Vagrant.configure("2") do |config|

  # Setup resource requirements
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.synced_folder ".", "/app", type: "nfs"

  # need a private network for NFS shares to work
  config.vm.network "private_network", ip: "192.168.2.2"

  # RabbitMQ Server Port Forwarding
  config.vm.network :forwarded_port, guest: 15672, host: 15672, auto_correct: true 
  config.vm.network :forwarded_port, guest: 5672, host: 5672, auto_correct: true 
  config.vm.network :forwarded_port, guest: 15673, host: 15673, auto_correct: true 
  config.vm.network :forwarded_port, guest: 5673, host: 5673, auto_correct: true 
  config.vm.network :forwarded_port, guest: 15674, host: 15674, auto_correct: true 
  config.vm.network :forwarded_port, guest: 5674, host: 5674, auto_correct: true 

  # Ubuntu 12.04
  config.vm.box = "hashicorp/precise64"

  # Install latest docker
  config.vm.provision "docker" do |d|
    d.pull_images "tutum/debian:squeeze"

    #docker build -t rjnienaber/rabbitmq /app
    d.build_image "/app/base", args: "-t rjnienaber/rabbitmq:base"
    d.build_image "/app/cluster1", args: "-t rjnienaber/rabbitmq:cluster1"
    d.build_image "/app/cluster2", args: "-t rjnienaber/rabbitmq:cluster2"
    d.build_image "/app/cluster3", args: "-t rjnienaber/rabbitmq:cluster3"
  end

  config.vm.provision "shell", inline: start_containers
end