# web-server-project-2

When setting this up on the cloud, ensure you have these ports opened (Port 80, 8080, 8081)

For the setup_nginx.sh script, after the script is done, record the IP address for the HA Proxy. We run this for 2 VMs/Droplets to create our backends

```bash
chmod +x setup_nginx.sh
./setup_nginx.sh

# Returns an IP address after successful setup
```

For the setup_HA_Proxy.sh script, pass in 2 arguments that are the IP addresses

```bash
chmod +x setup_HA_Proxy.sh
./setup_HA_Proxy.sh 127.0.0.1 127.0.0.2
```
