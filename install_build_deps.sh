echo "Install wget, git and dev tools"

command -v apt-get

if [ $? == 0 ]
then
  echo "DEB-based distro"
  sudo apt-get update
  sudo apt-get install -y --force-yes wget git build-essential
#  sudo apt-get install -y --force-yes ruby ruby-dev 
#  sudo apt-get install -y --force-yes rubygems
#  sudo gem install --no-ri --no-rdoc fpm
else
  echo "RPM-based distro"
  command -v yum
  if [ $? != 0 ]
  then
    echo "We need zypper here"
    sudo zypper clean -a
    sudo zypper -n install wget git
    sudo zypper -n install --type pattern Basis-Devel
#    sudo zypper -n install ruby-devel rpm-build rubygems
#    sudo gem install --no-ri --no-rdoc fpm
  else
    echo "We need yum here"
    optional_repo_name=`grep -h  -i server-optional /etc/yum.repos.d/* | sed "s/\[//" |sed "s/\]//"`
    sudo yum-config-manager --enable $optional_repo_name
    sudo yum clean all
    sudo yum install wget git -y
    sudo yum groupinstall 'Development Tools' -y
 #   sudo yum install ruby-devel rpm-build rubygems -y
 #   sudo gem install --no-ri --no-rdoc fpm
  fi
fi

# This durty hack is done to fix 'fpm.ruby2.1' problem
fpm_exec_name=`ls -1 /usr/bin/ | grep fpm`
if [ "$fpm_exec_name" != "fpm" ] ; then
  echo "fpm executable name is $fpm_exec_name, creating symlink"
  sudo ln -s /usr/bin/"$fpm_exec_name" /usr/bin/fpm
fi

echo "Download Golang"
go_binary="go1.9.linux-amd64.tar.gz"
wget https://storage.googleapis.com/golang/"$go_binary"
echo "Unpack Golang"
sudo tar -C /usr/local -xzf "$go_binary"

#echo 'export PATH=$PATH:/usr/local/go/bin' >> .profile

export PATH=$PATH:/usr/local/go/bin

echo "go get"
cd go
#go install github.com/mariadb-corporation/mrm
go get github.com/go-sql-driver/mysql
go get github.com/jmoiron/sqlx
go get github.com/juju/errors
go get github.com/sirupsen/logrus
go get gonum.org/v1/gonum/graph/simple
go get gonum.org/v1/gonum/graph/topo
go get github.com/spf13/cobra
go get github.com/spf13/viper
