#!/bin/bash

download_dir="/tmp/acpid"

check_acpid() {
  install_acpid=false
  acpid_working_version="acpid-2.0.31"
  acpid_current_version=$(acpid --version)
  if [ "$acpid_working_version" != "$acpid_current_version" ]; then
    install_acpid=true
    if [ ! -z "$acpid_current_version" ]; then
      yum -y remove acpid
      rm -rf /etc/acpi/events /etc/acpi/actions
    fi
  fi
}

download_acpid() {
  if "$install_acpid"; then
    acpid_tempdir="$download_dir/acpid"
    mkdir -p "$acpid_tempdir"
    pushd "$acpid_tempdir"
      wget https://www.softnas.com/software/acpid/acpid-2.0.31.tar.gz
    popd
  fi
}

install_acpid() {
  if "$install_acpid"; then
    acpid_tempdir="$download_dir/acpid"
    pushd "$acpid_tempdir"
      # build and install
      tar -xzf acpid-2.0.31.tar.gz && cd acpid-2.0.31
      ./configure --prefix=/usr --docdir=/usr/share/doc/acpid-2.0.31
      make
      make install
      install -v -m755 -d /etc/acpi/events /etc/acpi/actions
      install -v -m754 init/acpid /etc/init.d/
      cp -r samples /usr/share/doc/acpid-2.0.31
      cp config/power /etc/acpi/events
      cp config/power.sh /etc/acpi/actions
      chkconfig acpid on
      service acpid start
    popd "$acpid_tempdir"
    rm -rf "$acpid_tempdir"
  fi
}

check_acpid
download_acpid
install_acpid
