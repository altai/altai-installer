%define targetdir /opt/altai

Name:             altai-installer
Version:          1.0.2
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


%description
Chef-based installer for Altai


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{targetdir}
cp -a * %{buildroot}%{targetdir}
rm -f %{buildroot}%{targetdir}/COPYING* %{buildroot}%{targetdir}/*spec


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc COPYING*
/opt/altai
%config(noreplace) /opt/altai/{master,compute}-node.json


%changelog
