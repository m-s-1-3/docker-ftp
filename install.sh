#!/bin/bash -e

cp docke-ftp.service /etc/systemd/system/docker-ftp.service

systemctl enable docker-ftp.service
