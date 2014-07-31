#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: sql_server
# Recipe:: server
#
# Copyright:: 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


service_name = node['sql_server']['instance_name']
if node['sql_server']['instance_name'] == 'SQLEXPRESS'
  service_name = "MSSQL$#{node['sql_server']['instance_name']}"
end

static_ip_tcp_reg_key  = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\\' + node['sql_server']['reg_version'] +
  node['sql_server']['instance_name'] + '\MSSQLServer\SuperSocketNetLib\Tcp'
  
static_tcp_reg_key = static_ip_tcp_reg_key +'\IPAll'

node.set_unless['sql_server']['server_sa_password'] = node['sql_server']['sa_password']
node.save unless Chef::Config[:solo]

def win_friendly_path(path)
   path.gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR) if path
end
	
config_file_path = win_friendly_path(File.join(Chef::Config[:file_cache_path], "ConfigurationFile.ini"))
config_file_pathb = win_friendly_path(File.join(Chef::Config[:file_cache_path], "ConfigurationFileMSSMS.ini"))


template config_file_path do
  source "ConfigurationFile.ini.erb"
end

template config_file_pathb do
  source "ConfigurationFileMSSMS.ini.erb"
end

windows_package node['sql_server']['server']['package_name'] do
  source node['sql_server']['server']['url']
  checksum node['sql_server']['server']['checksum']
  timeout node['sql_server']['server']['installer_timeout']
  installer_type :custom
  options "/q /ConfigurationFile=#{config_file_path}"
  action :install
end

#windows_package node['sql_server']['management_studio']['package_name'] do
#  source node['sql_server']['management_studio']['url']
#  checksum node['sql_server']['management_studio']['checksum']
#  timeout node['sql_server']['server']['installer_timeout']
#  installer_type :custom
#  options "/q /ConfigurationFile=#{config_file_pathb}"
#  action :install
#end


service service_name do
  action :nothing
end

# set the static tcp port

%w{ \IP1 \IP2 \IP3 \IP4 \IP5 \IP6 \IP7 \IP8 \IP9 \IP10 \IP11 \IP12 }.each do |ipadd|
	
   registry_key static_ip_tcp_reg_key+ipadd do
	values [{ :name => 'Enabled', :type => :dword, :data => '00000001' }]
   end

end

registry_key static_tcp_reg_key do
  values [{ :name => 'TcpPort', :type => :string, :data => node['sql_server']['port'].to_s },
    { :name => 'TcpDynamicPorts', :type => :string, :data => '' }]
  notifies :restart, "service[#{service_name}]", :immediately
end

firewall_rule_name = "#{node['sql_server']['instance_name']} Static Port"

execute "open-static-port" do
  command "netsh advfirewall firewall add rule name=\"#{firewall_rule_name}\" dir=in action=allow protocol=TCP localport=#{node['sql_server']['port']}"
  returns [0,1,42] # *sigh* cmd.exe return codes are wonky
  not_if { SqlServer::Helper.firewall_rule_enabled?(firewall_rule_name) }
end

include_recipe 'sql_server::client'
