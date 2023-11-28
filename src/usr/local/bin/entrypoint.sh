#!/bin/bash
set -ex;
    
## Defaults ##
CA_URL=${CA_URL:-none};
REWRITE_TYPE=${REWRITE_TYPE:-none};
REWRITE_EXCLUDE=${REWRITE_EXCLUDE:-none};
    
if [ "${CA_URL}" != "none" ];then
    /usr/local/bin/cert-updater -p "${CA_URL}";
else 
    echo "CA Certificates: Nothing to import, CA_URL is not defined";
fi
    
if [ "${REWRITE_TYPE}" != "none" ];then
    echo "Apache Config: REWRITE_TYPE is defined, attempting to add rewrite config to enabled site"
    FILE="/usr/local/share/apache2/${REWRITE_TYPE,,}.rewrite"
    if [ -f $FILE ];then
        sed -i -e "/#REWRITE/{r$FILE" -e "d}" /etc/apache2/sites-enabled/default-ssl.conf
        echo "Apache Config: Using rewrite template ${FILE}";
        if [ "${REWRITE_EXCLUDE}" != "none" ];then
            echo "Apache Config: REWRITE_EXCLUDE is defined, setting rewrite to ignore the matched pattern ${REWRITE_EXCLUDE}"
            sed -i "s@#REWRITE_EXCLUDE@a$(printf %q "        RewriteRule ${REWRITE_EXCLUDE} - [L]")@g" /etc/apache2/sites-enabled/default-ssl.conf
        fi
    fi
else 
    echo "Apache Config: Using default site without rewrite, REWRITE is not defined"
fi
    
exec "$@"
echo "Initialization complete, container ready"
    
apachectl -k start -D FOREGROUND
