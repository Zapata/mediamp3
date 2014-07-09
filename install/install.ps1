$client = New-Object system.net.WebClient

# Download and install Git.
$client.DownloadFile("https://github.com/msysgit/msysgit/releases/download/Git-1.9.4-preview20140611/Git-1.9.4-preview20140611.exe", "C:\Users\Administrator\Downloads\Git.exe")
& "C:\Users\Administrator\Downloads\Git.exe" /NORESTART /SILENT

# Checkout MediaMp3
& "C:\Program Files (x86)\Git\bin\git" clone -q "https://github.com/Zapata/mediamp3.git" "C:\mediamp3"

# Install Microsoft Speech platform
& "C:\mediamp3\install\SpeechPlatformRuntime.msi" /norestart /quiet
& "C:\mediamp3\install\MSSpeech_TTS_fr-FR_Hortense.msi" /norestart /quiet

# Download and Install Ruby
$client.DownloadFile("http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p481-x64.exe?direct", "C:\Users\Administrator\Downloads\Ruby2.exe")
& "C:\Users\Administrator\Downloads\Ruby2.exe" /NORESTART /SILENT
$env:Path = $env:Path + ";C:\Ruby200-x64\bin\"

# Download and Install Ruby DevKit
$client.DownloadFile("http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe", "C:\Users\Administrator\Downloads\Ruby2-devkit.exe")
& "C:\Users\Administrator\Downloads\Ruby2-devkit.exe" -o"C:\Ruby200-x64\DevKit" -y
cd "C:\Ruby200-x64\DevKit"
& ruby dk.rb init
Add-Content config.yml "- C:\Ruby200-x64"
& ruby dk.rb install
& "C:\Ruby200-x64\DevKit\devkitvars.ps1"

# Install ruby dependencies.
& gem install bundle
cd C:\mediamp3
rm Gemfile.lock
& bundle install

# Save PATH:
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

Set-ExecutionPolicy -Scope CurrentUser -Force RemoteSigned


