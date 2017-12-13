# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'iOS' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'Google/SignIn'
  pod 'ProximityKit', '~> 1.2'
  pod 'SCLAlertView'
  pod 'Crashlytics'
  pod 'DALI', '~> 0.4.2'
  pod 'Socket.IO-Client-Swift'
  pod 'OneSignal', '>= 2.5.2', '< 3.0'

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
    pod 'DALI', '~> 0.4.2'
	
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
