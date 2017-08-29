echo "Install wget, git and dev tools"

command -v apt-get

if [ $? == 0 ]
then
  echo "DEB-based distro"
  sudo apt-get install -y --force-yes wget git ruby ruby-dev rubygems build-essential
else
  echo "RPM-based distro"
  command -v yum
  if [ $? != 0 ]
  then
    echo "We need zypper here"
    sudo zypper -n install wget git -y
    sudo zypper -n install --type pattern Basis-Devel
    sudo zypper -n install ruby-devel rpm-build rubygems -y
  else
    echo "We need yum here"
    sudo yum install wget git -y
    sudo yum groupinstall 'Development Tools' -y
    sudo yum install ruby-devel rpm-build rubygems -y
  fi
fi
gem install --no-ri --no-rdoc fpm

#sudo apt-get install  -y --force-yes wget git
#sudo zypper -n install wget git

echo "Download Golang"
go_binary="go1.9.linux-amd64.tar.gz"
wget https://storage.googleapis.com/golang/"$go_binary"
echo "Unpack Golang"
sudo tar -C /usr/local -xzf "$go_binary"

#echo 'export PATH=$PATH:/usr/local/go/bin' >> .profile

export PATH=$PATH:/usr/local/go/bin

echo "go install mrm"
cd go
go install github.com/mariadb-corporation/mrm
