# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'iOS' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'Google/SignIn'
  pod 'ProximityKit', '~> 1.2'
  pod 'SCLAlertView'
  pod 'Eureka'
  pod 'Crashlytics'
  pod 'DALI', :path => '~/Programming/DALI/Internal/framework'
  pod 'Socket.IO-Client-Swift'
  pod 'ChromaColorPicker'
  pod 'QRCodeReaderViewController'
  pod 'OneSignal', '>= 2.5.2', '< 3.0'
  pod 'FutureKit'

  # Pods for DALI Lab

  target 'iOSTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'iOSUITests' do
    inherit! :search_paths
    # Pods for testing
  end
end

target 'tvOS' do
	# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
	use_frameworks!
    pod 'DALI', :path => '~/Programming/DALI/Internal/framework'
	
	# Pods for DALI Lab
	
	target 'tvOSTests' do
		inherit! :search_paths
		# Pods for testing
	end
	
	target 'tvOSUITests' do
		inherit! :search_paths
		# Pods for testing
	end
end
