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


log("Start to install nova-billing")
node.set["mysql-billing-password"] = UUID.new().generate()

package "nova-billing"

mysql_create_database "billing" do
    user :billing
    password node["mysql-billing-password"]
end

template "/etc/nova-billing/settings.json" do
    source "nova-billing/settings.json.erb"
    mode 00660
    owner "nova-billing"
    group "root"
end


log("Start services"){level :debug}
%w( nova-billing-heart nova-billing-os-amqp).each do |service|
    service service do
        action [:enable, :restart]
	ignore_failure true
    end
end

log("nova-billing was succesfully installed")
