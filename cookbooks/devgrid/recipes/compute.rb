#    Altai Private Cloud 
#    Copyright (C) GridDynamics Openstack Core Team, GridDynamics
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 2.1 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU General Public License

require "rubygems"


log("Start to install nova-compute")

%w( dbus openstack-nova-compute ).each do |package_name|
    package package_name 
end

#FIXME without kernel won't work guestfs. 
#but in test enviroment packimage clean /boot/
#either tune packimage or scp /boot/* later
execute "update kernel" do
    command "yum install -y kernel"
end

execute "add qemu in kvm group" do
    command "usermod -a -G kvm qemu"
end

# Prevent virbr0 auto creation
log("Prevent virbr0 auto creation")
execute "Prevent virbr0 auto creation" do
    command "rm -rf /etc/libvirt/qemu/networks/autostart/*"
end


# Live-migration preparations
log("Live-migration preparations")
script "Patch libvirtd conf files for live migration" do
  interpreter "bash"
  user "root"
  code <<-EOH
  sed -i 's/#listen_tls/listen_tls/g' /etc/libvirt/libvirtd.conf
  sed -i 's/#listen_tcp/listen_tcp/g' /etc/libvirt/libvirtd.conf
  sed -i 's/#auth_tcp = \"sasl\"/auth_tcp = \"none\"/g' /etc/libvirt/libvirtd.conf
  sed -i 's/#LIBVIRTD_ARGS=\"--listen\"/LIBVIRTD_ARGS=\"--listen\"/g' /etc/sysconfig/libvirtd
  EOH
end


node["services"].push({"name"=>"nova_compute", "type"=>"amqp"})
%w( messagebus libvirtd nova-compute ).each do |service|
    service service do
	action [:enable, :restart]
    end
end

log("nova-compute was succesfully installed")
