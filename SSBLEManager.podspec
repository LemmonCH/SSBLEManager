Pod::Spec.new do |spec|

  spec.name         = "SSBLEManager"
  spec.version      = "1.0.3"
  spec.summary      = "蓝牙基础模块"
  spec.description  = <<-DESC
			                "蓝牙基础模块"
                      DESC
  spec.homepage     = "https://github.com/LemmonCH/SSBLEManager"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "LemmonCH" => "1806096107@qq.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/LemmonCH/SSBLEManager.git", :tag => "#{spec.version}" }
  spec.source_files = "SSBLEManager", "SSBLEManager/*.h"
  spec.public_header_files = "SSBLEManager/*.h"
  spec.frameworks   = "Foundation","CoreBluetooth"
end
