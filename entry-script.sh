#! /bin/bash
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo docker pull nginx:latest
sudo docker run --name mynginx1 -p 8080:80 -d nginx