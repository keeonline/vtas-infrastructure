#!/bin/bash
echo "This is the custom script starting" > ~/vtas.txt

apt-get update -y
apt-get install curl wget unzip -y

sudo apt-get install openjdk-11-jdk -y

java -v >> ~vtas.txt

echo "Custom script complete" >> ~/vtas.txt