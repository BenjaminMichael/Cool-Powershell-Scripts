#this script empties some temp directories
#it is dependent on a special reg key you create (line 7)
#it is dependent on a value you set for that key (line 8)
#it is dependent on SDelete being in a folder of your choosing (line 25)

$RegKeyPath = 'HKLM:\SOFTWARE\<# special key goes here #>\'
$value = "<# special value goes here.  this is set during the SCCM task sequence #>"
$specialValueExist = $false
$key = Get-Item -LiteralPath $RegKeyPath
$altKey = Get-Item -LiteralPath $altRegKeyPath
if ($Key.GetValue($Value) -ne $null){$specialValueExist = $true}else{if($altKey.GetValue($value) -ne $null){$specialValueExist = $true}}

Function confirmPath($potentialTarget){
if (test-path $potentialTarget){Get-ChildItem -Path $potentialTarget -Recurse -Filter * | ForEach-Object{if($_.LastWriteTime -lt (Get-Date).AddDays(-7)){secureDelete($_.VersionInfo.FileName)}}}
}

Function confirmDownloadsPath($potentialTarget){
    if (test-path $potentialTarget){Get-ChildItem -Path $potentialTarget -Recurse -Filter * | ForEach-Object{secureDelete($_.VersionInfo.FileName)}}
    }

Function secureDelete($this){
$myExpression= "C:\Windows\<# special folder goes here.  this is part of the wim #>\Bin\SDelete.exe -p 1 -s -q /accepteula '$($this)'"
Invoke-Expression "& $($myExpression)"
}

confirmPath("$($env:LOCALAPPDATA)\Microsoft\Windows\Temporary Internet Files\Content.Outlook\")
confirmPath("$($env:LOCALAPPDATA)\Microsoft\Windows\Temporary Internet Files\Content.MSO\")
confirmPath("$($env:USERPROFILE)\Local Settings\Temporary Internet Files\Content.MSO\")
confirmPath("$($env:USERPROFILE)\Local Settings\Temporary Internet Files\Content.Outlook\")
confirmPath($env:TEMP)

if ($specialValueExist){
confirmDownloadsPath("$($env:USERPROFILE)\downloads\")
$Recycler = (New-Object -ComObject Shell.Application).NameSpace(0xa)
$Recycler.items() | ForEach-Object { secureDelete($_.path) }
}
