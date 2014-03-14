#!/bin/sh
BASE=$(pwd)

# Mac OS X check
if [ $OSTYPE == "darwin13" ]; then
    #statements
    export FLAGS="--with-cc-opt='-Wno-deprecated-declarations'"
fi

cd src/
./configure \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --with-http_dav_module \
    --http-client-body-temp-path=/var/tmp/nginx/body \
    --http-proxy-temp-path=/var/tmp/nginx/proxy \
    --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
    --with-http_stub_status_module \
    --with-debug \
    --with-http_ssl_module \
    --with-pcre \
    --with-ipv6 \
    --add-module=${BASE}/pkgs/headers-more-nginx-module/ \
    --add-module=${BASE}/pkgs/smockron/nginx/ \
    --add-module=${BASE}/pkgs/requestid/ \
    ${FLAGS}

make
sudo make install