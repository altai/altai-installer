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

log("Start to install ganglia")

%w( ganglia-gmetad ganglia-gmond ganglia-gmond-modules-python ganglia-web libganglia php-fpm ).each do |package_name|
    package package_name 
end


template "/etc/ganglia/gmond.conf" do
    source "ganglia/gmond.conf.erb"
    mode 00644
    owner "root"
    group "root"
end


script "correct timezone and fix view permissions for ganglia" do
  interpreter "bash"
  user "root"
  code <<-EOH
  sed -i "s%;date.timezone =%date.timezone = $(cat /etc/sysconfig/clock | awk -F= {'print $2'})%g" /etc/php.ini  
  sed -i "s%readonly';%disabled';%g" /var/www/html/ganglia/conf_default.php
  sed -i "s%;security.limit_extensions =.*%security.limit_extensions = .php .php3 .php4 .php5 .css .jpg .jpeg .gif .js .png%g" /etc/php-fpm.d/www.conf
  EOH
end


log("Start ganglia services"){level :debug}
%w( php-fpm gmetad gmond ).each do |service|
    service service do
        action [:enable, :restart]
    end
end

log("ganglia was succesfully installed")
