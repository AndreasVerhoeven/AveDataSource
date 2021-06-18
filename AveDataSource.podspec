Pod::Spec.new do |s|
    s.name             = 'AveDataSource'
    s.version          = '1.0.0'
    s.summary          = 'Update TableViews and CollectionViews with ease'
    s.homepage         = 'https://github.com/AndreasVerhoeven/AveDataSource'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Andreas Verhoeven' => 'cocoapods@aveapps.com' }
    s.source           = { :git => 'https://github.com/AndreasVerhoeven/AveDataSource.git', :tag => s.version.to_s }
    s.module_name      = 'DHash'

    s.swift_versions = ['5.0']
    s.ios.deployment_target = '13.0'
    s.source_files = 'Sources/*.swift'
end
