$myOutput = @()

function nestedGroup($inputName){
Get-ADGroupMember $inputName | ForEach-Object {$myOutput += "$($_.name) inherited from $($inputName)"}
}


Get-ADGroup -SearchBase 'OU=Museum of Art,OU=Organizations,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu' -filter * | ForEach-Object {$myOutput += "`n" + $_.name ;Get-ADGroupMember $_} | ForEach-Object{if($_.objectClass -eq 'user'){$myOutput += $_.name}else{write-host $_; nestedGroup($_)}}
$myOutput |  Out-File C:\temp\UMMAGroups.csv