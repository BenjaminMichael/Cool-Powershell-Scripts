$myDN = #enter the distinuished name for the AD grop you want to run this report against

$myOutput = @()

function nestedGroup($inputName){
Get-ADGroupMember $inputName | ForEach-Object {$myOutput += "$($_.name) inherited from $($inputName)"}
}


Get-ADGroup -SearchBase $myDN -filter * | ForEach-Object {$myOutput += "`n" + $_.name ;Get-ADGroupMember $_} | ForEach-Object{if($_.objectClass -eq 'user'){$myOutput += $_.name}else{write-host $_; nestedGroup($_)}}
$myOutput |  Out-File C:\temp\UMMAGroups.csv
