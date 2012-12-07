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


log("Start to install focus")

node["mail-smtp-tls"] = node["mail-smtp-tls"] ? "True" : "False"
node.set["mysql-focus-password"] = UUID.new().generate()

package "memcached"
package "python-focus" 

mysql_create_database "focus" do
    user :focus
    password node["mysql-focus-password"]
end

#TODO gunicorne with listen on internal IP only 
node["config_files"].push("/etc/focus/local_settings.py")

template "/etc/focus/local_settings.py" do
    source "focus/local_settings.py.erb"
    mode 00660
    owner "focus"
    group "root"
end
template "/etc/focus/gunicorn_config.py" do
    source "focus/gunicorn_config.py.erb"
    mode 00660
    owner "focus"
    group "root"
end

execute "upload db" do 
    command "cat /etc/focus/{invitations_dump,configured_hostnames}.sql | mysql -u focus -p#{node['mysql-focus-password']} focus"
end

try "update tenant_id in config file with real id" do
    code <<-EOH
    export TENANT_ID=`cat /tmp/systenant.id`
    echo "Systenant id: $TENANT_ID"
    rm /tmp/systenant.id
    perl -i -pe 's/@~TENANT_ID~@/$ENV{TENANT_ID}/' /etc/focus/local_settings.py
    EOH
end

log("Start services"){level :debug}
service "memcached" do 
    action [:enable, :restart]
end

node["services"].push({
    "name"=>"focus", 
    "type"=>"UI", 
    "url"=>"http://#{node["master-ip-public"]}:8080/"
})

execute "create uploads dir" do
    command "mkdir -p -m 777 /var/lib/focus/uploads/files/"
end

%w( nginx focus ).each do |service|
    service service do
        action [:enable, :restart]
    end
end

log("focus was succesfully installed")
