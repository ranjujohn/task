#!/bin/bash
sudo apt-get -y install openjdk-8-jdk
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

pubname=`curl http://169.254.169.254/latest/meta-data/public-hostname`
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y apache2 software-properties-common certbot
sudo apt-get install -y certbot
cat > /etc/apache2/sites-available/002-ssl.conf <<EOF
<VirtualHost *:443>
        SSLEngine on
        SSLCertificateFile /etc/letsencrypt/live/${pubname}/cert.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/${pubname}/privkey.pem
        ServerName https://${pubname}
        SSLProtocol all -SSLv2 -SSLv3
</VirtualHost>
EOF
cat > /etc/apache2/sites-available/001-web.conf <<EOF
<VirtualHost *:80>
    ServerName ${pubname}
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
EOF
cat > certificate_create <<EOF
sudo certbot certonly --webroot -w /var/www/html -d ${pubname} --non-interactive --agree-tos --email demo@www.example.com
EOF
chmod a+x certificate_create
/bin/bash certificate_create
sudo a2ensite 001-web.conf
#sudo a2ensite 002-ssl.conf
sudo a2enmod proxy_http
#sudo a2enmod ssl
sudo systemctl restart apache2
sudo echo "00      10    *       *       *       root    /usr/bin/certbot renew --no-self-upgrade" >> /etc/crontab
