#!/bin/bash
wget -q https://s3.eu-central-1.amazonaws.com/leverton-dev-test/hello.jar
mkdir -p /app
cp hello.jar /app

tee /etc/systemd/system/webapp.service << EOF
[Unit]
Description=Web App

[Service]
ExecStart=/usr/bin/java -jar /app/hello.jar
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable webapp
sudo systemctl start webapp
