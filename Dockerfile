# bshp/ocie:version_tag, e.g 22.04 unquoted
ARG OCIE_VERSION
ARG PHP_VERSION=8.1
ARG SQL_VERSION=5.11.0
    
# Optional: Change Timezone
ARG TZ=America/North_Dakota/Center
    
FROM bshp/apache2:${OCIE_VERSION}
    
LABEL org.opencontainers.image.authors="jason.everling@gmail.com"
    
ARG TZ
ARG PHP_VERSION
ARG SQL_VERSION
    
ENV OCIE_TYPES=${OCIE_TYPES}:/etc/apache2
ENV PHP_VERSION=${PHP_VERSION}
ENV PHP_TIMEZONE=${OS_TIMEZONE}
ENV PHP_ERROR_LOG=/var/log/apache2/php_error.log
ENV PHP_MAX_EXECUTION_TIME=60
ENV PHP_MAX_INPUT_TIME=60
ENV PHP_MEMORY_LIMIT=128M
ENV PHP_POST_MAX_SIZE=8M
ENV PHP_UPLOAD_MAX_FILESIZE=8M
ENV SQL_VERSION=${SQL_VERSION}
    
RUN <<-"EOD" bash
    set -eu;
    export $(cat /etc/environment | xargs);
    #Add Microsoft Repository, for SQL Server Driver
    wget --quiet "https://packages.microsoft.com/keys/microsoft.asc" -O- | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg;
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/ubuntu/${OS_BASE}/prod ${OS_CODENAME} main" \
        | tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null;
    #Set PHP Packages
    PKGS="php${PHP_VERSION},libapache2-mod-php,php-cli,php-dev,unzip,zip,libaio1,libcurl4,libgss3,libldap-common,libmcrypt-dev,libxml2,libxslt1.1,\
        libzip-dev,locales,msodbcsql18,odbcinst,sassc,unixodbc,unixodbc-dev,php-bcmath,php-curl,php-gd,php-iconv,php-intl,php-json,php-ldap,\
        php-mbstring,php-mysql,php-odbc,php-opcache,php-pdo,php-pspell,php-readline,php-shmop,php-soap,php-simplexml,php-sqlite3,php-xml,php-xmlrpc,\
        php-zip,php-pear,php-xdebug";
    #Install Packages
    ocie --dhparams "-size ${DH_PARAM_SIZE}" --pkg "-add $(echo $PKGS | tr -d ' ')" --keys "-subject ${CERT_SUBJECT}";
    echo "Creating Custom PHP ini settings";
    INI=$(cat <<-'EOT' | sed 's/^ *//g'
        ;Custom PHP Settings
        display_errors = Off
        display_startup_errors = Off
        error_reporting = E_ALL & ~E_DEPRECATED
        expose_php = Off
        file_uploads = Off
        html_errors = Off
        ignore_repeated_errors = Off
        log_errors = On
        session.cookie_lifetime = 0
        session.cookie_secure = On
        session.name = user_session
        error_log = ${PHP_ERROR_LOG}
        max_execution_time = ${PHP_MAX_EXECUTION_TIME}
        max_input_time = ${PHP_MAX_INPUT_TIME}
        memory_limit = ${PHP_MEMORY_LIMIT}
        post_max_size = ${PHP_POST_MAX_SIZE}
        upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
        [Date]
        date.timezone = ${PHP_TIMEZONE}
EOT
);
    echo "$INI" > /etc/php/01-custom.ini;
    cat /etc/php/01-custom.ini;
    ln -s /etc/php/01-custom.ini /etc/php/${PHP_VERSION}/apache2/conf.d/01-custom.ini;
    #Cleanup
    ocie --clean "-base";
    echo "Finished installing base system";
    echo "Custom PHP INI Location: [ /etc/php/01-custom.ini ], Link: [ /etc/php/${PHP_VERSION}/apache2/conf.d/01-custom.ini ]";
EOD
    
RUN <<-"EOD" bash
    set -eu;
    echo "Installing SQL Server PHP Extensions";
    export $(cat /etc/environment | xargs);
    EXT_DIR=$(php-config --extension-dir);
    SQL_TMP="$(mktemp -d)";
    SQL_CAT=$(echo "${PHP_VERSION}" | sed 's/[^0-9]*//g');
    wget --quiet "https://github.com/microsoft/msphpsql/releases/download/v${SQL_VERSION}/Ubuntu${OS_VERSION}-${PHP_VERSION}.tar" -O $SQL_TMP/mssql.tar;
    tar -xf $SQL_TMP/mssql.tar -C $SQL_TMP --strip-components=1;
    mv $SQL_TMP/php_sqlsrv_${SQL_CAT}_nts.so $EXT_DIR/sqlsrv.so;
    mv $SQL_TMP/php_pdo_sqlsrv_${SQL_CAT}_nts.so $EXT_DIR/pdo_sqlsrv.so;
    printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/${PHP_VERSION}/apache2/conf.d/sqlsrv.ini;
    printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/${PHP_VERSION}/apache2/conf.d/pdo_sqlsrv.ini;
    rm -rf $SQL_TMP;
    echo "Finished installing SQL Server PHP Extensions";
EOD
    
EXPOSE 80 443
    
ENTRYPOINT ["/bin/bash"]
