#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Starting setup..."

# Update and install Nginx and HAProxy
echo "Installing Nginx and HAProxy..."
apt update
apt install -y nginx haproxy

# Configure the first Nginx instance on port 8081
echo "Configuring Nginx instance on port 8081..."
cat > /etc/nginx/sites-available/app1 <<EOF
server {
    listen 8081;
    server_name localhost;

    location / {
        proxy_pass http://localhost:3000; # Your Node.js app
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Configure the second Nginx instance on port 8082
echo "Configuring Nginx instance on port 8082..."
cat > /etc/nginx/sites-available/app2 <<EOF
server {
    listen 8082;
    server_name localhost;

    location / {
        proxy_pass http://localhost:3000; # Your Node.js app
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable both Nginx instances
ln -s /etc/nginx/sites-available/app1 /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/app2 /etc/nginx/sites-enabled/

# Restart Nginx to apply changes
echo "Restarting Nginx..."
systemctl restart nginx

# Configure HAProxy
echo "Configuring HAProxy..."
cat >> /etc/haproxy/haproxy.cfg <<EOF

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    server app1 127.0.0.1:8081 check
    server app2 127.0.0.1:8082 check

listen stats
    bind *:8080
    stats enable
    stats uri /stats
    stats auth admin:admin
EOF

# Restart HAProxy to apply changes
echo "Restarting HAProxy..."
systemctl restart haproxy

echo "Setup complete."
echo "You can access the load balancer at http://localhost"
echo "HAProxy stats are available at http://localhost:8080/stats with login 'admin' and password 'admin'"
