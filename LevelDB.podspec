Pod::Spec.new do |spec|
  spec.name         = "LevelDB.swift"
  spec.version      = "0.0.4"
  spec.summary      = "Simple but versatile Swift wrapper around the LevelDB key-value storage library written at Google."
  spec.homepage     = "https://bitbucket.org/pyrtsa/LevelDB.swift"

  spec.license      = "All rights reserved"

  spec.author       = { "Pyry Jahkola" => "pyry.jahkola@iki.fi" }
  spec.social_media_url = "https://twitter.com/pyrtsa"

  spec.source       = { :git => "git@bitbucket.org:pyrtsa/leveldb.swift.git", :tag => "v#{spec.version}" }
  spec.source_files = "LevelDB/**/*.swift", "External"

  spec.requires_arc = true

  spec.ios.deployment_target = "8.0"
  spec.osx.deployment_target = "10.10"
end
