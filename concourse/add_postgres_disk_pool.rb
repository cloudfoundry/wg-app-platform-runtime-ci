#!/usr/bin/env ruby

require 'yaml'
cf_manifest_path = ARGV[0]
manifest = YAML.load_file cf_manifest_path

disk_pool = {"cloud_properties" => { "type" => "io2", "iops" => 2000 }, "disk_size" => 100000, "name" => "postgres-persistent-disk"}
manifest["disk_pools"] = [disk_pool]

manifest['jobs'].find {|job| job['name'] == 'postgres_z1' }.delete('persistent_disk')
manifest['jobs'].find {|job| job['name'] == 'postgres_z1' }['persistent_disk_pool'] = "postgres-persistent-disk"

File.open(cf_manifest_path, 'w+') {|f| f.write YAML.dump(manifest) }
