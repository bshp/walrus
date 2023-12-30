FROM bshp/apache2:latest
    
LABEL org.opencontainers.image.authors="jason.everling@gmail.com"
    
ARG PHP_VERSION=8.1
ARG SQL_VERSION=5.11.0
    
ENV WALRUS_HOME=/etc/walrus
ENV WALRUS_BOOT=${WALRUS_HOME}/boot.ini
ENV PHP_VERSION=${PHP_VERSION}
ENV PHP_TIMEZONE=${OS_TIMEZONE}
ENV PHP_ERROR_LOG=/var/log/apache2/php_error.log
ENV PHP_MAX_EXECUTION_TIME=60
ENV PHP_MAX_INPUT_TIME=60
ENV PHP_MEMORY_LIMIT=128M
ENV PHP_POST_MAX_SIZE=8M
ENV PHP_UPLOAD_MAX_FILESIZE=8M
ENV SQL_VERSION=${SQL_VERSION}
    
RUN set eux; \
    wget --quiet "https://packages.microsoft.com/keys/microsoft.asc" -O- | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg; \
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/ubuntu/${OS_BASE}/prod ${OS_CODENAME} main" \
        | tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null; \
    apt-get update && ACCEPT_EULA=Y apt-get install --no-install-recommends -y \
    libaio1 \
    libcurl4 \
    libgss3 \
    libldap-common \
    libmcrypt-dev \
    libxml2 \
    libxslt1.1 \
    libzip-dev \
    locales \
    msodbcsql18 \
    odbcinst \
    sassc \
    unixodbc \
    unixodbc-dev \
    unzip \
    zip \
    php${PHP_VERSION} \
    libapache2-mod-php \
    php-bcmath \
    php-curl \
    php-cli \
    php-dev \
    php-gd \
    php-iconv \
    php-intl \
    php-json \
    php-ldap \
    php-mbstring \
    php-mysql \
    php-odbc \
    php-opcache \
    php-pdo \
    php-pspell \
    php-readline \
    php-shmop \
    php-soap \
    php-simplexml \
    php-sqlite3 \
    php-xml \
    php-xmlrpc \
    php-zip \
    php-pear \
    php-xdebug; \
    echo "; Custom PHP Settings" > /etc/php/01-custom.ini; \
    ln -s /etc/php/01-custom.ini /etc/php/${PHP_VERSION}/apache2/conf.d/01-custom.ini; \
    mkdir ${WALRUS_HOME} && chmod -R 0750 ${WALRUS_HOME}; \
    echo "## Walrus Setup Initialization" > ${WALRUS_BOOT}; \
    echo "WALRUS_PHP_VERSION=${PHP_VERSION}" >> ${WALRUS_BOOT}; \
    echo "WALRUS_SQL_VERSION=${SQL_VERSION}" >> ${WALRUS_BOOT}; \
    chmod -R a+x /usr/local/bin; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    echo "Finished installing base system";
    
RUN set eux; \
    echo "Installing SQL Server PHP Extensions"; \
    EXT_DIR=$(php-config --extension-dir); \
    SQL_TMP="$(mktemp -d)"; \
    SQL_CAT=$(echo "${PHP_VERSION}" | sed 's/[^0-9]*//g'); \
    wget --quiet "https://github.com/microsoft/msphpsql/releases/download/v${SQL_VERSION}/Ubuntu${OS_VERSION}-${PHP_VERSION}.tar" -O $SQL_TMP/mssql.tar; \
    tar -xf $SQL_TMP/mssql.tar -C $SQL_TMP --strip-components=1; \
    mv $SQL_TMP/php_sqlsrv_${SQL_CAT}_nts.so $EXT_DIR/sqlsrv.so; \
    mv $SQL_TMP/php_pdo_sqlsrv_${SQL_CAT}_nts.so $EXT_DIR/pdo_sqlsrv.so; \
    printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/${PHP_VERSION}/apache2/conf.d/sqlsrv.ini; \
    printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/${PHP_VERSION}/apache2/conf.d/pdo_sqlsrv.ini; \
    rm -rf $SQL_TMP; \
    echo "Finished installing SQL Server PHP Extensions";
    
COPY ./src/ ./
    
EXPOSE 80 443
    
ENTRYPOINT ["/usr/local/bin/app-run"]
