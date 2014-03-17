#!/bin/sh
BASE=$(pwd)
PLUGIN_NAME="rocketbox"

# Install WGET
sudo yum install wget


# Flush log
echo "" > build.log


# pull submodules
echo "!!! Checking out submodules"
git submodule update --init --recursive  >> build.log 2>&1


# Get UTHASH for Smockron
git submodule update --init --recursive ${BASE}/pkgs/smockron  >> build.log 2>&1


# Mac OS X check
echo "!!! Probing environment"
if [ $OSTYPE == "darwin13" ]; then

    echo "!!! Building for OS X"
    # Fix deprecated md5 features
    export FLAGS="--with-cc-opt='-Wno-deprecated-declarations'"

elif [ $OSTYPE == "linux-gnu" ]; then
    
    echo "!!! Building for Linux"
    # Check if zeromq is installed
    if [[ -n $(ldconfig -p |grep zmq.so.3) ]]; then
        yum remove zeromq zeromq-devel
        wget http://download.zeromq.org/zeromq-3.2.2.tar.gz  >> build.log 2>&1
        tar zxvf zeromq-3.2.2.tar.gz  >> build.log 2>&1 && cd zeromq-3.2.2  >> build.log 2>&1
        ./configure  >> build.log 2>&1
        make  >> build.log 2>&1 && sudo make install >> build.log 2>&1
	    echo /usr/local/lib | tee -a /etc/ld.so.conf.d/local.conf
	    sudo ldconfig
        cd ..
        rm -rf zeromq*
    fi

    # Install required packages
    sudo yum install pcre-devel openssl-devel

fi


# Enter into nginx source dir
cd src/


# Apply NGINX Patch
echo "Patching Rocketbox..."
patch -p1 -s < ../patches/001_nginx_ver.patch >> build.log


# Create nginx user
sudo useradd -s /bin/false $PLUGIN_NAME

# Configure
echo "Configuring Rocketbox..."
./configure \
    --sbin-path=/usr/sbin/$PLUGIN_NAME \
    --conf-path=/etc/rocketbox/$PLUGIN_NAME.conf \
    --error-log-path=/var/log/$PLUGIN_NAME/error.log \
    --http-log-path=/var/log/$PLUGIN_NAME/access.log \
    --pid-path=/var/run/$PLUGIN_NAME.pid \
    --lock-path=/var/lock/$PLUGIN_NAME.lock \
    --http-client-body-temp-path=/var/tmp/$PLUGIN_NAME/body \
    --http-proxy-temp-path=/var/tmp/$PLUGIN_NAME/proxy \
    --http-fastcgi-temp-path=/var/tmp/$PLUGIN_NAME/fastcgi \
    --with-debug \
    --with-http_ssl_module \
    --without-http_autoindex_module \
    --without-http_ssi_module \
    --user=$PLUGIN_NAME \
    --group=$PLUGIN_NAME \
    --with-pcre \
    --with-ipv6 \
    --add-module=${BASE}/pkgs/headers-more-nginx-module/ \
    --add-module=${BASE}/pkgs/smockron/nginx/ \
    --add-module=${BASE}/pkgs/requestid/ \
    ${FLAGS} >> build.log 2>&1


# Building
echo "Building Rocketbox..." 
make >> build.log 2>&1


# Installing nginx
echo "Installing Rocketbox..."
sudo make install >> build.log 2>&1


# Create nginx dirs
sudo mkdir -p /var/tmp/$PLUGIN_NAME/{body,proxy,fastcgy}



# Test
NGINX_TEST=$(sudo /usr/sbin/$PLUGIN_NAME -t >> build.log 2>&1)
if [[ $? -eq 0 ]]; then
    echo "Rocketbox installed successfully"
else
    echo "There was an issue installing rocketbox"
fi
