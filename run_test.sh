#!/bin/bash

set -x

ulimit -n
rm -rf LOGS
export MDBCI_VM_PATH=$HOME/vms; mkdir -p $MDBCI_VM_PATH
export target=`echo $target | sed "s/?//g"`
export name=`echo $name | sed "s/?//g"`
export value=`echo $value | sed "s/?//g"`

. ~/mrm-jenkins/configure_log_dir.sh

export dir=`pwd`
export repo_dir=$dir/repo.d/

echo "Bringing up VMa"
~/mrm-jenkins/create_config.sh
res=$?

echo "Loading VMs parameters to variables"
set -a
. $MDBCI_VM_PATH/${name}_network_config
set +a

echo "Setting up replication"
~/mrm-jenkins/setup_repl/setup_repl.sh

echo "Generating maxscale.cnf"
cp ~/mrm-jenkins/cnf/maxscale/replication.cnf maxscale.cnf.tmp
eval "cat <<EOF
$(maxscale.cnf.tmp)
EOF" > maxscale.cnf

export scpopt="-i $maxscale_keyfile -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=120 "
export sshopt="ssh $scpopt $maxscale_whoami@$maxscale_network"

echo "Copying maxscale.cnf to VM"
scp $scpopt maxscale.cnf $maxscale_whoami@$maxscale_network:~/
$sshopt 'sudo cp ~/maxscale.cnf /etc/'

cd $MDBCI_VM_PATH/$name
if [ "$do_not_destroy_vm" != "yes" ] ; then
	vagrant destroy -f
        rm ~/vagrant_lock
	echo "clean  up done!"
fi
cd $dir
exit $res
