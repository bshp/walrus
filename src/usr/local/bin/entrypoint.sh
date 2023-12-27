#!/bin/bash
    
## Initialization ##
/usr/local/bin/cert-updater;
/usr/local/bin/app-config;
    
/usr/sbin/apachectl -k start -D FOREGROUND
