#
# Author:: Julian Wilde (jules@jules.com.au)
# Cookbook Name:: nodejs
# Recipe:: install_from_binary
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

Chef::Recipe.send(:include, NodeJs::Helper)

node.force_override['nodejs']['install_method'] = 'binary' # ~FC019

# FIXME: Handle s390x, ppc64, arm64, armv61, armv71, ppc64le
# Shamelessly borrowed from http://docs.chef.io/dsl_recipe_method_platform.html
# Surely there's a more canonical way to get arch?
arch = if node['kernel']['machine'] =~ /armv6l/
         'arm-pi' # assume a raspberry pi
       else
         node['kernel']['machine'] =~ /x86_64/ ? 'x64' : 'x86'
       end

# package_stub is for example: "node-v6.9.1-linux-x64.tar.xz"
version = "v#{node['nodejs']['version']}/"
prefix = node['nodejs']['prefix_url'][node['nodejs']['engine']]

# Choose short platform name and file extension based on our platform family
# Used to buidl the URL
case node['platform_family']
when 'windows'
  platform = 'win'
  extension = '7z'
when 'mac_os_x'
  platform = 'darwin'
  extension = 'tar.xz'
when 'aix'
  platform = 'aix'
  extension = 'tar.gz'
when 'smartos', 'omnios', 'openindiana', 'opensolaris', 'solaris2', 'nexentacore'
  platform = 'sunos'
  extension = 'tar.xz'
else
  platform = 'linux'
  extension = 'tar.xz'
end

if node['nodejs']['engine'] == 'iojs'
  filename = "iojs-v#{node['nodejs']['version']}-#{platform}-#{arch}.#{extension}"
  archive_name = 'iojs-binary'
  binaries = ['bin/iojs', 'bin/node']
else
  filename = "node-v#{node['nodejs']['version']}-#{platform}-#{arch}.#{extension}"
  archive_name = 'nodejs-binary'
  binaries = ['bin/node']
end

binaries.push('bin/npm') if node['nodejs']['npm']['install_method'] == 'embedded'

if node['nodejs']['binary']['url']
  nodejs_bin_url = node['nodejs']['binary']['url']
  checksum = node['nodejs']['binary']['checksum']
else
  nodejs_bin_url = ::URI.join(prefix, version, filename).to_s
  checksum = node['nodejs']['binary']['checksum']["#{platform}_#{arch}"]
end

if node['nodejs']['binary']['win_install_dir']
  win_install_dir = node['nodejs']['binary']['win_install_dir']
else
  # FIXME: Use Program Files(x86) if installing 32-bit version on 64-bit windows!
  win_install_dir = "C:\\Program Files\\#{archive_name}"
end

ark archive_name do
  url nodejs_bin_url
  version node['nodejs']['version']
  checksum checksum
  has_binaries binaries
  append_env_path true
  win_install_dir win_install_dir
  action :install
end
