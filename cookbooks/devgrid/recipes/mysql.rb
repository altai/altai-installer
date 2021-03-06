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

log("Start to install mysql")

%w( mysql-server MySQL-python ).each do |package_name|
    package package_name do 
	action :install
    end
end

log("Apply config with binding address"){level :debug}
node["config_files"].push("/etc/my.cnf")
template "/etc/my.cnf" do
    source "my.cnf.erb"
    mode 00644
    owner "root"
    group "root"
end

log("Setup root user"){level :debug}
node["services"].push({
    "name"=>"mysql", 
    "type"=>"mysql", 
    "ip"=>node["master-ip-private"],
    "port"=>3306
})  

# - in default setup there are exists authorization record for user ""@hostname.
# - Later in setup we add access to users username@%. 
# - During auth procedure, mysql select all records from "user" database,
# relevant for given connection, sort it and take _FIRST_ record. If it
# won't success, "connection refused" retruned.
# - so if user try to login from the same host, record for gust user
# becomes first
#
# To fix this issue, guest users completely removed.

try "setup_root_password" do
    environment ( {'PASSWD' => node["mysql-root-password"]} )
    code <<-EOH
    service mysqld stop
    perl -i.bak -pe 's/(\\[mysqld\\])/\\1\\nskip-grant-tables\\nskip-networking/' /etc/my.cnf
    service mysqld start
    mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('$PASSWD') WHERE User='root'"
    mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('$PASSWD') WHERE User='root'"
    mysql -u root -e "DELETE FROM mysql.user WHERE user=''"
    mv /etc/my.cnf{.bak,}
    service mysqld restart
    chkconfig mysqld on
    EOH
end

log("Mysql was succesfully installed")
