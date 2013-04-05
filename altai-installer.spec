%define targetdir /opt/altai

Name:             altai-installer
Version:          1.1.2
Release:          0%{?dist}
Summary:          Installer for Altai
License:          GNU LGPL 2.1
Vendor:           Grid Dynamics International, Inc.
URL:              http://www.griddynamics.com/openstack
Group:            Development

Source0:          %{name}-%{version}.tar.gz
BuildRoot:        %{_tmppath}/%{name}-%{version}-build
BuildArch:        noarch
Requires:         altai-chef-gems
Requires:         libselinux-utils
Requires:         net-tools
Requires:         python-netaddr
Requires:         python-argparse


%description
Chef-based installer for Altai


%prep
%setup -q
rm -f *spec

%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{targetdir}
cp -a * %{buildroot}%{targetdir}
rm -f %{buildroot}%{targetdir}/COPYING* %{buildroot}%{targetdir}/*spec


%clean
rm -rf %{buildroot}


%pre
if [ -n "$(rpm -qa openstack-nova*api*)" ]; then
    config_file=master
else
    config_file=compute
fi
config_file=/opt/altai/${config_file}-node.json
if [ -r $config_file ]; then
    chmod 600 $config_file
    mv $config_file /tmp/altai-node.json
fi


%post
config_file=/tmp/altai-node.json
[ ! -r $config_file ] || mv $config_file /opt/altai/altai-node.json


%files
%defattr(-,root,root,-)
%doc COPYING*
/opt/altai
%config(noreplace) /opt/altai/*-node.json


%changelog
