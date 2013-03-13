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
#require "uuid"

log("Start to install hsflowd")

package "hsflowd"

template "/etc/hsflowd.conf" do
    source "hsflowd/hsflowd.conf.erb"
    mode 00644
    owner "root"
    group "root"
end

log("Start hsflowd services"){level :debug}

service "hsflowd" do
    action [:enable, :restart]
end

log("hsflowd was succesfully installed")