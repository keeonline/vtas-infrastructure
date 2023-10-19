#!/bin/bash
echo "This is the custom script starting" > ~/repo.txt

apt-get update -y
apt-get install curl wget unzip -y

apt-get update -y
apt-get instal ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

usermod -aG docker adminuser 

docker run --rm --name vtas-repo -d -p 8080:8080 keeonline/vtas-repo:latest

echo "Custom script complete" >> ~/repo.txt