#!/bin/bash

# User Creation --> app
sudo useradd -m app -s /bin/bash
sudo usermod --password $(openssl passwd -6 'app') app
echo "app  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/app

#Php and Composer Installation
sudo apt install php-fpm php-mysql -y
sudo apt update
sudo apt install php-mbstring php-xml php-bcmath -y
sudo apt install php-cli unzip -y
cd /home/ubuntu
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
echo $HASH
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
composer -v

#AmazonCodeDeploy Agent
sudo apt update -y
sudo apt install ruby wget -y
cd /home/ubuntu
wget https://aws-codedeploy-ca-central-1.s3.ca-central-1.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto
sudo systemctl start codedeploy-agent.service
sudo systemctl enable codedeploy-agent.service
# sudo systemctl status codedeploy-agent.service


# AmazonCloudWatch Agent
sudo apt update -y
wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip -O AmazonCloudWatchAgent.zip
sudo apt install -y unzip
unzip -o AmazonCloudWatchAgent.zip
sudo ./install.sh
sudo mkdir -p /usr/share/collectd/
sudo touch /usr/share/collectd/types.db 
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:Queue-app-config -s
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
# { 
# "status": "running", 
# "starttime": "2020-06-07T10:04:41+00:00", 
# "version": "1.245315.0" 
# }
# sudo systemctl status amazon-cloudwatch-agent.service
sudo systemctl start amazon-cloudwatch-agent.service
sudo systemctl enable amazon-cloudwatch-agent.service

