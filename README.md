Apache with PHP    
    
````
docker run \
  --publish 80:80 \
  --publish 443:443 \
  --volume httpd_app:/var/www/html \
  --env CA_URL="https://YOUR_CA_URL/" \
  --env VADC_IP_ADDRESS="YOUR_LOAD_BALANCER_IP" \
  --env VADC_IP_HEADER="YOUR_IP_HEADER" \
  --detach --name httpd bshp/walrus:latest
````  
