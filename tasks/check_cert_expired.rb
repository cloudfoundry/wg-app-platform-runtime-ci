#!/usr/bin/env ruby

require 'tempfile'
require 'date'

cert_file = ARGV[0]
expires_in_days = ARGV[1].to_i
if expires_in_days.nil?
  expires_in_days = 0
end

cert_contents = File.read(cert_file).strip
tmp_cert_file = Tempfile.new('tmp-cert')
tmp_cert_file.write(cert_contents)
tmp_cert_file.rewind
output = `openssl x509 -in #{tmp_cert_file.path} -noout -dates 2>/dev/null | grep notAfter`
if !$?.success?
  tmp_cert_file.close
  tmp_cert_file.unlink
  exit 0
end
expiration=output.split("=")[1]
expired = Date.parse(expiration) < ( Date.today + expires_in_days)
if expired
  puts cert_file
end
tmp_cert_file.close
tmp_cert_file.unlink
