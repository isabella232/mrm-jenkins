#!/bin/bash

# this script copyies stuff to VM and run build on VM

set -x

echo "target is $target"
rm -rf $pre_repo_dir/$target/$image
mkdir -p $pre_repo_dir/$target/SRC
mkdir -p $pre_repo_dir/$target/$image

export work_dir="go/src/github.com/mariadb-corporation/mrm"
export orig_image=$image

echo $sshuser
echo $platform
echo $platform_version

ssh $sshopt "sudo rm -rf $work_dir"
echo "copying stuff to $image machine"
ssh $sshopt "mkdir -p $work_dir"

cp ~/mrm-jenkins/install_build_deps.sh .
export install_script="install_build_deps.sh"
export build_script="build_linux_amd64.sh"

rsync -avz  --progress --delete -e "ssh $scpopt" ./ $sshuser@$IP:$work_dir/ 
if [ $? -ne 0 ] ; then
        echo "Error copying stuff to $image machine"
        exit 2
fi

if [ "$already_running" != "ok" ] ; then
	export already_running="false"
fi

export remote_build_cmd="export already_running=\"$already_running\"; \
	export work_dir=\"$work_dir\"; \
	export platform=\"$platform\"; \
	export platform_version=\"$platform_version\"; \
	export source=\"$scm_source\"; \
	export BUILD_TAG=\"$BUILD_TAG\"; \
	"

if [ "$already_running" != "ok" ]
then
    echo "install packages on $image"
    ssh $sshopt "$remote_build_cmd ./$work_dir/$install_script"
    installres=$?

    if [ $installres -ne 0 ]
    then
        exit $installres
    fi

    dir1=`pwd`
    #cd ~/mdbci
    $HOME/mdbci/mdbci snapshot take --path-to-nodes $box --snapshot-name clean
    cd $dir1
else
	echo "already running VM, not installing deps"
fi

#echo "run build on $image"
#ssh $sshopt "$remote_build_cmd cd go/src/github.com/mariadb-corporation/mrm;"  'export PATH=$PATH:/usr/local/go/bin;' "./$build_script"
echo "Build and packaging"
ssh $sshopt '$remote_build_cmd cd go/src/github.com/mariadb-corporation/mrm;  export PATH=$PATH:/usr/local/go/bin:$HOME/.local/bin:$HOME/bin; echo $PATH; ./package_linux_amd64.sh'
if [ $? -ne 0 ] ; then
        echo "Error build on $image"
        exit 4
fi


echo "copying binaries"
mkdir -p ~/repository/$target/$image/mrm/
scp $scpopt $sshuser@$IP:./go/bin/* ~/repository/$target/$image/mrm/
scp $scpopt $sshuser@$IP:./go/src/github.com/mariadb-corporation/mrm/*.gz ~/repository/$target/mrm/$image/
scp $scpopt $sshuser@$IP:./go/src/github.com/mariadb-corporation/mrm/*.deb ~/repository/$target/mrm/$image/
scp $scpopt $sshuser@$IP:./go/src/github.com/mariadb-corporation/mrm/*.rpm ~/repository/$target/mrm/$image/

echo "package building for $target done!"

#if [ "$no_repo" != "yes" ] ; then
#	~/build-scripts/create_remote_repo.sh $image $IP $target
#fi
