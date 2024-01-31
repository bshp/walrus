Apache with PHP
    
Since this uses Ubuntu 22.04 as the base, only PHP 8.1.x is available, v8.2 will be added when Ubuntu 24.04 LTS is released in Apr 2024, well before the v8.1 EOL.  
This route is chosen because it does not rely on a 3rd party repo/ppa for PHP, easier on our compliance department.
    
#### Base OS:    
Ubuntu Server LTS - Latest
    
#### Packages:    
Updated weekly from the official upstream Ubuntu LTS, see [Apache2 Base](https://github.com/bshp/apache2) for additional packages included.
````
php8.x
php-cli
php-dev
libaio1
libapache2-mod-php
libcurl4
libgss3
libldap-common
libmcrypt-dev
libxml2
libxslt1.1
libzip-dev
locales
msodbcsql18
pdo_sqlsrv
php-bcmath
php-curl
php-gd
php-iconv
php-intl
php-json
php-ldap
php-mbstring
php-mysql
php-odbc
php-opcache
php-pdo
php-pspell
php-readline
php-shmop
php-soap
php-simplexml
php-sqlite3
php-xml
php-xmlrpc
php-zip
php-pear
php-xdebug
odbcinst
sassc
sqlsrv
unixodbc
unixodbc-dev
unzip
zip
````
    
## Environment Variables:  
    
see [Ocie Environment](https://github.com/bshp/ocie/blob/main/Environment.md) for more variables
    
````
PHP_TIMEZONE=${OS_TIMEZONE}
PHP_ERROR_LOG=/var/log/apache2/php_error.log
PHP_MAX_EXECUTION_TIME=60
PHP_MAX_INPUT_TIME=60
PHP_MEMORY_LIMIT=128M
PHP_POST_MAX_SIZE=8M
PHP_UPLOAD_MAX_FILESIZE=8M
````
    
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
/usr/local/bin/ociectl --run;
````
````
/usr/sbin/apachectl -k start -D FOREGROUND;
````
    
## Tags:  
    
latest = v8.1  
v8.1 = PHP 8.1.x, SQL 5.11.0 (EOL is Nov. 2024)  
    
#### Build:
    
````
docker build . --pull --build-arg VERSION=22.04 --build-arg PHP_VERSION=8.1 --build-arg SQL_VERSION=5.11.0 --tag your_tag --no-cache
````

