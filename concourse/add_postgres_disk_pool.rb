#!/usr/bin/env ruby

require 'yaml'

cf_manifest_path = ARGV[0]
manifest = YAML.load_file cf_manifest_path

copy_obj = manifest["resource_pools"][0]

resource_pool =
{
  "cloud_properties" =>
   {
     "instance_type" =>  "m3.large",
     "ephemeral_disk" =>  {
      "size" =>  102400,
      "type" =>  "gp2"
     },
    "availability_zone" =>  "us-east-1a"
   },
 "name" => "runner_z1",
 "env" => copy_obj["env"],
 "stemcell" => copy_obj["stemcell"],
 "network" => "cf1"
}

manifest["resource_pools"].push(resource_pool)

disk_pool =
{
  "cloud_properties" =>
  {
    "type" => "io1",
    "iops" => 2000
  },
  "disk_size" => 100000,
  "name" => "postgres-persistent-disk"
}
manifest["disk_pools"] = [disk_pool]

manifest['jobs'].find {|job| job['name'] == 'postgres_z1' }.delete('persistent_disk')
manifest['jobs'].find {|job| job['name'] == 'postgres_z1' }['persistent_disk_pool'] = "postgres-persistent-disk"

File.open(cf_manifest_path, 'w+') {|f| f.write YAML.dump(manifest) }
