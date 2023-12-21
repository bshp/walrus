#!/bin/bash
set -ex;
    
## Certificates ##
if [ "${CERT_PATH}" != "" ];then
    /usr/local/bin/cert-updater;
fi
    
## Initialization ##
/usr/local/bin/app-config;
    
apachectl -k start -D FOREGROUND
