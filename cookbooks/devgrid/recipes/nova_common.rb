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


log("Start to install openstack-nova-common")


node.set["mysql-dns-password"] = UUID.new().generate()

%w(openstack-nova-common).each do |pkg|
    package pkg
end

node["config_files"].push("/etc/nova/nova.conf")
template "/etc/nova/nova.conf" do
    source "nova/nova.conf.erb"
    mode 00600
    owner "nova"
    group "nobody"
end

node["config_files"].push("/etc/nova/api-paste.ini")
template "/etc/nova/api-paste.ini" do
    source "nova/api-paste.ini.erb"
    mode 00600
    owner "nova"
    group "nobody"
end


log("openstack-nova-common was succesfully installed")
