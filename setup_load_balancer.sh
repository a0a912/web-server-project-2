#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Starting setup..."

# Function to check if a port is in use
function check_port() {
  if lsof -i:$1 > /dev/null; then
    echo "Port $1 is already in use. Please free it or use a different port."
    exit 1
  fi
}

# Check if required ports are available
check_port 80
check_port 8080
check_port 8081
check_port 8082

# Update and install Nginx and HAProxy
echo "Installing Nginx and HAProxy..."
apt update
if ! apt install -y nginx haproxy; then
  echo "Failed to install Nginx or HAProxy. Exiting."
  exit 1
fi

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
if ! systemctl restart nginx; then
  echo "Failed to restart Nginx. Exiting."
  exit 1
fi

# Configure HAProxy with port checks
echo "Configuring HAProxy..."

cat > /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000

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
if ! systemctl restart haproxy; then
  echo "Failed to restart HAProxy. Exiting."
  exit 1
fi

echo "Setup complete."
echo "You can access the load balancer at http://localhost"
echo "HAProxy stats are available at http://localhost:8080/stats with login 'admin' and password 'admin'"
