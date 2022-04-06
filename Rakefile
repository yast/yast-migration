require "yast/rake"

Yast::Tasks.submit_to :sle15sp4

Yast::Tasks.configuration do |conf|
  conf.skip_license_check << /\.desktop$/
  conf.skip_license_check << /\.svg$/
end
