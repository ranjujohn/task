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

pubname=`curl http://169.254.169.254/latest/meta-data/public-hostname`
sudo apt-get update
sudo apt-get install -y apache2 software-properties-common
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y certbot
cat > sslfile.txt <<EOF
<VirtualHost *:443>
        SSLEngine on
        SSLCertificateFile /etc/letsencrypt/live/www.example.com/cert.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/www.example.com/privkey.pem
        ServerName https://www.example.com
        SSLProtocol all -SSLv2 -SSLv3
        ProxyPass / http://127.0.0.1:8080/
        ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
EOF
sed -i "s/www.example.com/$pubname/g" sslfile.txt
cat > certificate_create <<EOF
sudo certbot certonly --webroot -w /var/www/html -d www.example.com  --non-interactive --agree-tos --email demo@www.example.com
EOF
chmod a+x certificate_create
sed -i "s/www.example.com/$pubname/g" certificate_create
/bin/bash certificate_create
cp sslfile.txt /etc/apache2/sites-available/002-ssl.conf
sudo a2ensite 002-ssl.conf
sudo a2enmod proxy_http
sudo a2enmod ssl
sudo systemctl restart apache2
if [ $? == 0 ]; then
 echo "please check https://$pubname"
fi
sudo echo "00      10    *       *       *       root    /usr/bin/certbot renew --no-self-upgrade" >> /etc/crontab
