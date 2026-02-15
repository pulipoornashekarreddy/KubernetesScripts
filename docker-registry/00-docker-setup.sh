
#!/bin/bash
# file name 00-docker-setup.sh
# sudo nano 00-docker-setup.sh
# sudo bash 00-docker-setup.sh

# This script sets up a local Docker registry with authentication on the host machine.
# It will ask you to create a username and password for the registry, which will be stored in an htpasswd file.
sudo mkdir -p /opt/registry/auth
sudo apt install apache2-utils -y
sudo htpasswd -Bc /opt/registry/auth/htpasswd admin

# below command will stop and remove existing registry container if it exists, then start a new one with the specified configuration

sudo docker stop cleanerp-registry
sudo docker rm cleanerp-registry

sudo docker run -d \
  --name cleanerp-registry \
  -p 127.0.0.1:5000:5000 \
  -v /opt/registry:/var/lib/registry \
  -v /opt/registry/auth:/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2

# Verification step: Check if the registry is running and accessible
# You can use the following command to test the registry:
# curl http://localhost:5000/v2/
# Should return 401 Unauthorized
# curl https://docker.cleanerp.com/v2/
# Should return 401 Unauthorized
# docker login docker.cleanerp.com
# Login with the username and password you created earlier. If successful, you should see a "Login Succeeded" message.
# curl https://docker.cleanerp.com/v2/
# {"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":null}]}