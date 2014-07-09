Param(
#  [Parameter(Mandatory=$True)]
   [string]$inputFile = "C:\texte.txt",
	
#   [Parameter(Mandatory=$True)]
   [string]$outputFile = "C:\audio.wav",

   [int]$pitch = 7,

   [int]$speed = 2

)

Add-Type -Path ((Split-Path -Parent $MyInvocation.MyCommand.Path) + "\Microsoft.Speech.dll")

$content = Get-Content $inputFile

$speaker = New-Object Microsoft.Speech.Synthesis.SpeechSynthesizer
$speaker.SelectVoice("Microsoft Server Speech Text to Speech Voice (fr-FR, Hortense)")
$speaker.SetOutputToWaveFile($outputFile)
$speaker.Speak($content)
$speaker.Dispose()
