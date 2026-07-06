cask "converta" do
  version "1.2.0"
  sha256 "4a5741102929559f5d98dfe4eb533c3c7eb9ae505dd1f246fce884a1870dc1c6"

  url "https://github.com/PavlovIvan1/converta/archive/refs/tags/v#{version}.tar.gz"
  name "Converta"
  desc "Native macOS video format converter (webm, mp4, mov, mkv, avi, gif)"
  homepage "https://github.com/PavlovIvan1/converta"

  depends_on macos: :ventura
  depends_on formula: "ffmpeg"

  preflight do
    pkg_dir = Pathname.glob(staged_path/"**/Package.swift").first.dirname

    system_command "/usr/bin/swift",
                    args: ["build", "-c", "release", "--package-path", pkg_dir.to_s],
                    print_stdout: true

    app_dir = staged_path/"Converta.app"
    (app_dir/"Contents/MacOS").mkpath
    (app_dir/"Contents/Resources").mkpath

    system_command "/bin/cp",
                    args: [pkg_dir/".build/release/Converta", app_dir/"Contents/MacOS/Converta"]
    system_command "/bin/cp",
                    args: [pkg_dir/"Resources/AppIcon.icns", app_dir/"Contents/Resources/AppIcon.icns"]

    File.write(app_dir/"Contents/Info.plist", <<~PLIST)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>CFBundleExecutable</key>
          <string>Converta</string>
          <key>CFBundleIconFile</key>
          <string>AppIcon.icns</string>
          <key>CFBundleIdentifier</key>
          <string>com.example.Converta</string>
          <key>CFBundleName</key>
          <string>Converta</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
          <key>CFBundleShortVersionString</key>
          <string>#{version}</string>
          <key>CFBundleVersion</key>
          <string>1</string>
          <key>LSMinimumSystemVersion</key>
          <string>13.0</string>
          <key>NSHighResolutionCapable</key>
          <true/>
      </dict>
      </plist>
    PLIST
  end

  app "Converta.app"
end
