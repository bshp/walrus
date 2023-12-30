Apache with PHP    
    
#### Base OS:    
Ubuntu Server LTS - Latest
    
#### Packages:    
Updated weekly from the official upstream Ubuntu LTS, see [Apache2 Base](https://github.com/bshp/apache2) for packages added.
    
## Environment Variables:  
see [Base Image](https://github.com/bshp/apache2/blob/master/Dockerfile) for more variables
````
PHP_TIMEZONE=${OS_TIMEZONE}
PHP_ERROR_LOG=/var/log/apache2/php_error.log
PHP_MAX_EXECUTION_TIME=60
PHP_MAX_INPUT_TIME=60
PHP_MEMORY_LIMIT=128M
PHP_POST_MAX_SIZE=8M
PHP_UPLOAD_MAX_FILESIZE=8M
````
    
#### Note:    
Some need to be set for certain functions when used direct with app-run, see [Base Scripts](https://github.com/bshp/apache2/tree/master/src/usr/local/bin) for more info
    
#### Direct:  
````
docker run \
  -p 80:80 \
  -p 443:443 \
  -v httpd_app:/var/www/html \
  -e VADC_IP_ADDRESS="YOUR_LOAD_BALANCER_IP" \
  -e VADC_IP_HEADER="YOUR_IP_HEADER" \
  -d bshp/walrus:latest
````
#### Custom:  
Add at end of your entrypoint script either of:  
````
/usr/local/bin/app-run;
````
````
/usr/sbin/apachectl -k start -D FOREGROUND;
````
    
## Tags:  
Since this uses Ubuntu 22.04 as the base, only PHP 8.1.x is available, v8.2 will be added when Ubuntu 24.04LTS is released in Apr 2024, well before the v8.1 EOL  
    
latest = v8.1  
v8.1 = PHP 8.1.x, SQL 5.11.0 (EOL is Nov. 2024)  
    
#### Build:
    
````
docker build . --pull --build-arg PHP_VERSION=8.1 --build-arg SQL_VERSION=5.11.0 --tag your_tag --progress=plain
````

