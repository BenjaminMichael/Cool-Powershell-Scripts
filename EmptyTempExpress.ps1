$RegKeyPath = 'HKLM:\SOFTWARE\MiWorkspace\'
$altRegKeyPath = 'HKLM:\SOFTWARE\WOW6432Node\MiWorkspace\'
$value = "FINCore"
$finCoreValueExist = $false
$key = Get-Item -LiteralPath $RegKeyPath
$altKey = Get-Item -LiteralPath $altRegKeyPath
if ($Key.GetValue($Value) -ne $null){$finCoreValueExist = $true}else{if($altKey.GetValue($value) -ne $null){$finCoreValueExist = $true}}

Function confirmPath($potentialTarget){
if (test-path $potentialTarget){Get-ChildItem -Path $potentialTarget -Recurse -Filter * | ForEach-Object{if($_.LastWriteTime -lt (Get-Date).AddDays(-7)){secureDelete($_.VersionInfo.FileName)}}}
}

Function confirmDownloadsPath($potentialTarget){
    if (test-path $potentialTarget){Get-ChildItem -Path $potentialTarget -Recurse -Filter * | ForEach-Object{secureDelete($_.VersionInfo.FileName)}}
    }


Function secureDelete($this){
$myExpression= "C:\Windows\EUC\Bin\SDelete.exe -p 1 -s -q /accepteula '$($this)'"
Invoke-Expression "& $($myExpression)"
}

confirmPath("$($env:LOCALAPPDATA)\Microsoft\Windows\Temporary Internet Files\Content.Outlook\")
confirmPath("$($env:LOCALAPPDATA)\Microsoft\Windows\Temporary Internet Files\Content.MSO\")
confirmPath("$($env:USERPROFILE)\Local Settings\Temporary Internet Files\Content.MSO\")
confirmPath("$($env:USERPROFILE)\Local Settings\Temporary Internet Files\Content.Outlook\")
confirmPath($env:TEMP)

if ($finCoreValueExist){
confirmDownloadsPath("$($env:USERPROFILE)\downloads\")
$Recycler = (New-Object -ComObject Shell.Application).NameSpace(0xa)
$Recycler.items() | ForEach-Object { secureDelete($_.path) }
}
