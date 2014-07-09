- Git (https://github.com/msysgit/msysgit/releases/download/Git-1.9.4-preview20140611/Git-1.9.4-preview20140611.exe)
- RubyInstaller (http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p481-x64.exe?direct)
- RubyDev kit (http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe) 
- (cd devkit) ruby dk.rb init
- (cd devkit) ruby dk.rb install
- git clone https://github.com/Zapata/mediamp3.git
- copy config.rb
- gem install bundle
- rm Gemfile.lock
- bundle install

- Install bin\SpeechPlatformRuntime.msi
- Install bin\MSSpeech_TTS_fr-FR_Hortense.msi


http://learn-powershell.net/2013/12/04/give-powershell-a-voice-using-the-speechsynthesizer-class/

PS C:\Users\Administrator> Add-Type -LiteralPath "C:\Program Files\Microsoft SDKs\Speech\v11.0\Assembly\Microsoft.Speech
.dll"
PS C:\Users\Administrator> $object = New-Object Microsoft.Speech.Synthesis.SpeechSynthesizer
PS C:\Users\Administrator>  $object.GetInstalledVoices().VoiceInfo

Gender                : Female
Age                   : Adult
Name                  : Microsoft Server Speech Text to Speech Voice (fr-FR, Hortense)
Culture               : fr-FR
Id                    : TTS_MS_fr-FR_Hortense_11.0
Description           : Microsoft Server Speech Text to Speech Voice (fr-FR, Hortense)
SupportedAudioFormats : {Microsoft.Speech.AudioFormat.SpeechAudioFormatInfo}
AdditionalInfo        : {[, ], [Age, Adult], [AudioFormats, 18], [Gender, Female]...}

PS C:\Users\Administrator> $object.SetOutputToWaveFile("C:\users\Administrator\Desktop\test.wav")
PS C:\Users\Administrator> $object.GetInstalledVoices().VoiceInfo
PS C:\Users\Administrator> $object.Speak("ceci est un pipe")
PS C:\Users\Administrator> $object.Dispose()
