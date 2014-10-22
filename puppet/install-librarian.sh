#!/bin/sh

# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR=/etc/puppet/

# NB: librarian-puppet might need git installed. If it is not already installed
# in your basebox, this will manually install it at this point using apt or yum

$(which apt-get > /dev/null 2>&1)
FOUND_APT=$?
$(which yum > /dev/null 2>&1)
FOUND_YUM=$?

$(which git > /dev/null 2>&1)
FOUND_GIT=$?
if [ "$FOUND_GIT" -ne '0' ]; then
  echo 'Attempting to install git.'

  if [ "${FOUND_YUM}" -eq '0' ]; then
    yum -q -y makecache
    yum -q -y install git
    echo 'git installed.'
  elif [ "${FOUND_APT}" -eq '0' ]; then
    apt-get -q -y update
    apt-get -q -y install git
    echo 'git installed.'
  else
    echo 'No package installer available. You may need to install git manually.'
  fi
else
  echo 'git found.'
fi

if [ "${FOUND_APT}" -eq '0' ]; then
  $(dpkg --get-selections | grep -v deinstall | grep -E "^ruby[0-9]\.[0-9]\.[0-9]-dev$")
  FOUND_DEVKIT=$?
  if [ "${FOUND_DEVKIT}" -ne '0' ]; then
    echo 'Attempting to install ruby devkit.'
    RUBY=$(dpkg --get-selections | grep -v deinstall | grep -E "^ruby[0-9]\.[0-9]\.[0-9]\\s" | sed -e "s/\s.*//")
    apt-get -q -y update
    apt-get -q -y install "$RUBY-dev"
  else
    echo 'ruby devkit found.'
  fi
  ## TODO: Add yum version of ruby devkit here
else
  echo 'ruby devkit may be missing.'
fi

if [ ! -d "$PUPPET_DIR" ]; then
  mkdir -p $PUPPET_DIR
fi
cp /vagrant/puppet/Puppetfile $PUPPET_DIR

if [ "$(gem search -i librarian-puppet)" = "false" ]; then
  gem install librarian-puppet
  cd $PUPPET_DIR && librarian-puppet install --clean
else
  cd $PUPPET_DIR && librarian-puppet update
fi