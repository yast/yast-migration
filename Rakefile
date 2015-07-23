require "yast/rake"

Yast::Tasks.configuration do |conf|
  conf.skip_license_check << /\.desktop$/
  # internal only module
  conf.obs_api = "https://api.suse.de/"
  conf.obs_project = "Devel:YaST:online_migration"
  conf.obs_target = "SLE_12"
  conf.obs_sr_project = "Devel:YaST:online_migration"
end
