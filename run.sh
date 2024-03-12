#! usr/bin/bash

sudo docker build -t optimization .
sudo docker run --platform linux/amd64 optimization 
