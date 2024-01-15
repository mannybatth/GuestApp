source 'https://github.com/CocoaPods/Specs.git'
source 'https://bitbucket.org/yikesdev/cocoapod-spec-repo.git'
platform :ios, '9.0'

def ga_pods
    
    pod 'PKAlertController'
    pod 'SVProgressHUD'
    pod 'PubNub','~> 4.0'
    pod 'libPhoneNumber-iOS', '~> 0.8.4'
    pod 'MMDrawerController'    
    pod 'SCPageViewController', :git => 'https://github.com/likebeats/SCPageViewController', :branch => 'master'
    pod 'HexColors', '< 3.0'
    pod 'Colours', '5.6.2'
    pod 'M13BadgeView'
    pod 'SAMKeychain'
    pod 'SDWebImage'
    pod 'Fabric'
    pod 'Crashlytics'
	
    # Private pods (remote)
    pod 'YikesGenericEngine', :path => 'yikesgenericengine'
    pod 'YikesSharedModel', :path => 'yikessharedmodel'
    pod 'YikesEngineSP', :path => 'yikesengine'
    pod 'YikesEngineMP', :path => 'yikesenginemp'
    pod 'YKSUIModuleSignup'#, :path => '../yksuimodulesignup'


end

target 'YikesGuestApp' do
    use_frameworks!
    ga_pods
end

#post_install do |installer|
#    installer.pods_project.build_configurations.each do |config|
#        config.build_settings['SDKROOT'] = 'iphoneos9.3'
#    end
#end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'YikesEngineSP'
            target.build_configurations.each do |config|
                if config.name == 'Debug'
                    config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)','-DDEBUG']
                    else
                    config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)','-DRELEASE']
                end
            end
        end
    end
end

# target '# YikesEngineMP' do
# 	use_frameworks!
# 	pod 'YikesEngineMP', :path => '../yikesenginemp'
# 	pod 'YikesSharedModel', :path => '../yikessharedmodel'
# end
