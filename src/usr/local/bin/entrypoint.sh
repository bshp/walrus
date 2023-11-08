#!/bin/bash
set -ex;
    
## Defaults ##
GEN_KEYS=${GEN_KEYS:-none};
CA_URL=${CA_URL:-none};
VADC_IP_ADDRESS=${VADC_IP_ADDRESS:-none};
VADC_IP_HEADER=${VADC_IP_HEADER:-none};
APACHE_LOG=${APACHE_LOG:-none};

## Keygen ##
echo "Keygen: Checking for certificate generation"
if [[ -f "/etc/ssl/server.key" ]] || [[ -f "/etc/ssl/server.pem" ]];then
    echo "Keygen: Certificate exist, checking if one should be generated"
else
    echo "Keygen: Certificate DOES NOT exist"
    GEN_KEYS=true;
fi
    
if [ ${GEN_KEYS} = true ];then
    echo "Keygen: New Certificate will be generated"
    openssl dhparam -out /etc/ssl/dhparams.pem 2048
    openssl req -newkey rsa:2048 -x509 -nodes \
        -keyout /etc/ssl/server.key -new \
        -out /etc/ssl/server.pem \
        -subj /CN=localhost -sha256 -days 3650
fi
    
PEM_SHA1=$(openssl x509 -noout -fingerprint -sha1 -in /etc/ssl/server.pem | cut -f2 -d"=" | sed "s/://g" | awk '{print tolower($0)}')
echo "Keygen: Finished, Certificate Thumbprint: $PEM_SHA1"
############
    
echo "CA Certificates: Checking for CA Import"
if [ "${CA_URL}" != "none" ];then
    echo "CA Certificates: The following URL will be searched ${CA_URL}"
    LOCAL_STORE="/usr/local/share/ca-certificates"
    cd /usr/local/share/ca-certificates
    wget -r -nH -A *_CA.crt ${CA_URL}
    for CA_CRT in /usr/local/share/ca-certificates/*.crt; do
        CA_NAME=$(openssl x509 -noout -subject -nameopt multiline -in $CA_CRT | sed -n 's/ *commonName *= //p')
        ${JAVA_HOME}/bin/keytool -import -trustcacerts -cacerts -storepass changeit -noprompt -alias "$CA_NAME" -file $CA_CRT >/dev/null 2>&1 | echo "CA Certificates: Added certificate to cacert, $CA_CRT"
    done
    update-ca-certificates
    cd /
else 
    echo "CA Certificates: Nothing to import, CA_URL is not defined"
fi
    
echo "Remote IP: Checking for Remote IP settings"
if [ "${VADC_IP_ADDRESS}" != "none" ];then
    echo "Remote IP: Found load a balancer ip address set, ${VADC_IP_ADDRESS} , attempting to configure modules"
    if [ "${VADC_IP_HEADER}"  == "none" ];then
        echo "Remote IP: Found load a balancer ip address set but VADC_IP_HEADER was not found and is required, NOT configuring modules"
    else 
        a2enmod remoteip 
        VADC_IP_REG=$(echo "${VADC_IP_ADDRESS}" | sed -e 's/\s/\|/g')
        MOD_REMOTE_IP=$(cat <<-EOF
<IfModule remoteip_module>
    RemoteIPInternalProxy ${VADC_IP_ADDRESS}
    RemoteIPHeader ${VADC_IP_HEADER}
</IfModule>
EOF
);
        echo "$MOD_REMOTE_IP" > /etc/apache2/mods-enabled/remoteip.conf
        echo "Remote IP: Apache2 module configured"
    fi
else 
    echo "Remote IP: Did not find VADC_IP_ADDRESS and VADC_IP_HEADER, NOT configuring modules"
fi

if [ "${APACHE_LOG}" != "none" ];then
    echo "Apache Config: APACHE_LOG is defined, setting log location to ${APACHE_LOG}"
    sed -i "s|APACHE_LOG_DIR=.*|APACHE_LOG_DIR=${APACHE_LOG}|g" /etc/apache2/envvars
else 
    echo "Apache Config: Using default log location, APACHE_LOG is not defined"
fi
    
exec "$@"
echo "Initialization complete, container ready"
    
apachectl -k start -D FOREGROUND
