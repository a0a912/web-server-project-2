#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "Starting setup..."

IP_ADDRESS=$(curl -s ifconfig.me)

# Function to check if a port is in use
function check_port() {
  if lsof -i:$1 > /dev/null; then
    echo "Port $1 is already in use. Please free it or use a different port."
    exit 1
  fi
}

# Check if required ports are available
check_port 80
check_port 8081

# Update and install Nginx
echo "Installing Nginx..."
apt update
if ! apt install -y nginx; then
  echo "Failed to install Nginx. Exiting."
  exit 1
fi

# Configure the Nginx instance on port 8081
echo "Configuring Nginx instance on port 8081..."
cat > /etc/nginx/sites-available/app1 <<EOF
server {
    listen 8081;
    server_name $IP_ADDRESS;

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

# Restart Nginx to apply changes
echo "Restarting Nginx..."
if ! systemctl restart nginx; then
  echo "Failed to restart Nginx. Exiting."
  exit 1
fi

echo "Your public IP address is: $IP_ADDRESS"
echo "$IP_ADDRESS"