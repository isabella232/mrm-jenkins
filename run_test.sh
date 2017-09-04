#!/bin/bash

# $1 - "debug" means do not install Maxscale
ulimit -n
rm -rf LOGS
export MDBCI_VM_PATH=$HOME/vms; mkdir -p $MDBCI_VM_PATH
export target=`echo $target | sed "s/?//g"`
export name=`echo $name | sed "s/?//g"`
export value=`echo $value | sed "s/?//g"`

. ~/mrm-jenkins/configure_log_dir.sh

export dir=`pwd`
export repo_dir=$dir/repo.d/

~/mrm-jenkins/create_config.sh
res=$?



cd $MDBCI_VM_PATH/$name
if [ "$do_not_destroy_vm" != "yes" ] ; then
	vagrant destroy -f
        rm ~/vagrant_lock
	echo "clean  up done!"
fi
cd $dir
exit $res
