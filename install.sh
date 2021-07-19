#!/bin/bash

module_name='data-lhlh-ngproxy'
plugin="plugin"
install_dir="/home/lhlh/"$module_name


echo "[info] install data-lhlh-ngproxy begin..."

$install_dir/sbin/nginx -s stop -p $install_dir -c conf/nginx.conf

chmod 755 configure
./configure  --prefix=$install_dir --with-stream --add-module=stream-lua-nginx-module/ --with-luajit
gmake
gmake install

mkdir -p $install_dir/logs
mkdir -p $install_dir/conf
mkdir -p /tmp/$module_name/

cp -r $plugin $install_dir/
cp -r $plugin/ip-whitelist.list $install_dir/conf/
cp -r $plugin/cmd-whitelist.list $install_dir/conf/
cp -r $plugin/nginx.conf $install_dir/conf/
cp -r $plugin/ngproxy.ini $install_dir/conf/
cp -r $install_dir/nginx/sbin $install_dir
cp -r $plugin/start.sh $install_dir/sbin/

rm -rf $install_dir/bin /tmp/$module_name/
rm -rf $install_dir/site /tmp/$module_name/
rm -rf $install_dir/resty.index /tmp/$module_name/
rm -rf $install_dir/nginx /tmp/$module_name/

cd $install_dir
$install_dir/sbin/nginx -p ./ -c $install_dir/conf/nginx.conf


echo "[info] install data-qkpack-ngproxy end..."
