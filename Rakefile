require "yast/rake"

Yast::Tasks.configuration do |conf|
  conf.skip_license_check << /\.desktop$/
  # internal only module
  conf.obs_api = "https://api.suse.de/"
  conf.obs_project = "Devel:YaST:Head"
  conf.obs_target = "SLE-12-SP1"
  conf.obs_sr_project = "SUSE:SLE-12-SP1:GA"
end
