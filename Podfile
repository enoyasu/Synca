# Podfile for Synca
# Run `pod install` to integrate Google Mobile Ads SDK

platform :ios, '17.0'
use_frameworks!
inhibit_all_warnings!

target 'Synca' do
  # AdMob (Google Mobile Ads SDK)
  # 有効にする場合は以下のコメントを外してください:
  # pod 'Google-Mobile-Ads-SDK'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      config.build_settings['SWIFT_VERSION'] = '5.9'
    end
  end
end
