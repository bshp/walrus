FROM bshp/apache2:latest

MAINTAINER jason.everling@gmail.com

ARG PHP_VERSION=8.1
ARG SQL_VERSION=5.11.0

RUN set eux; \
    apt-get update && apt-get install --no-install-recommends -y \
    gnupg \
    libaio1 \
    libcurl4 \
    libgss3 \
    libldap-common \
    libmcrypt-dev \
    libxml2 \
    libxslt1.1 \
    libzip-dev \
    locales \
    odbcinst \
    sassc \
    unixodbc \
    unixodbc-dev \
    unzip \
    zip \
    php \
    libapache2-mod-php \
    php-bcmath \
    php-curl \
    php-cli \
    php-dev \
    php-gd \
    php-intl \
    php-json \
    php-ldap \
    php-mbstring \
    php-mysql \
    php-odbc \
    php-opcache \
    php-pspell \
    php-readline \
    php-soap \
    php-xml \
    php-xmlrpc \
    php-zip \
    php-pear; \
    echo "; Custom PHP Settings" > /etc/php/01-custom.ini; \
    ln -s /etc/php/01-custom.ini /etc/php/${PHP_VERSION}/apache2/conf.d/01-custom.ini; \
    mkdir /var/log/php && chown -R www-data:www-data /var/log/php && chmod -R 0750 /var/log/php; \
    echo "Finished installing base system";

RUN set eux; \
    echo "Installing SQL Server PHP Extensions"; \
    OS_BASE=$(sed -n 's/^VERSION_ID="\(.*\)"/\1/p' </etc/os-release); \
    EXT_DIR=$(php-config --extension-dir); \
    SQL_TMP="$(mktemp -d)"; \
    OS_VERSION=$(echo "${OS_BASE}" | sed 's/[^0-9]*//g'); \
    OS_CODENAME=$(sed -n 's/^VERSION_CODENAME=\(.*\)/\1/p' </etc/os-release); \
    SQL_CAT=$(echo "${PHP_VERSION}" | sed 's/[^0-9]*//g'); \
    wget --quiet "https://packages.microsoft.com/keys/microsoft.asc" -O- | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg; \
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/ubuntu/${OS_BASE}/prod ${OS_CODENAME} main" \
        | tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null; \
    wget --quiet "https://github.com/microsoft/msphpsql/releases/download/v${SQL_VERSION}/Ubuntu${OS_VERSION}-${PHP_VERSION}.tar" -O $SQL_TMP/mssql.tar; \
    tar -xf $SQL_TMP/mssql.tar -C $SQL_TMP --strip-components=1; \
    mv $SQL_TMP/php_sqlsrv_${SQL_CAT}_nts.so $EXT_DIR/sqlsrv.so && mv $SQL_TMP/php_pdo_sqlsrv_${SQL_CAT}_nts.so $EXT_DIR/pdo_sqlsrv.so; \
    rm -rf $SQL_TMP; \
    printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/${PHP_VERSION}/mods-available/sqlsrv.ini; \
    printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/${PHP_VERSION}/mods-available/pdo_sqlsrv.ini; \
    phpenmod -v ${PHP_VERSION} sqlsrv pdo_sqlsrv; \
    apt-get update && ACCEPT_EULA=Y apt-get install --no-install-recommends -y msodbcsql18; \
    echo "Finished installing SQL Server PHP Extensions";

COPY ./src/ ./

RUN set eux; \
    chown root:root /usr/local/bin/entrypoint.sh; \
    chmod a+x /usr/local/bin/entrypoint.sh;

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
