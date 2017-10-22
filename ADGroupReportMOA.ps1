#
#get all the members of an ad group and get members of any subgroups
#


$distinguishedName = #paste an ad-group distinguished name here
$myOutput = @()

function nestedGroup($inputName){
Get-ADGroupMember $inputName | ForEach-Object {$myOutput += "$($_.name) inherited from $($inputName)"}
}


Get-ADGroup -SearchBase $distinguishedName -filter * | ForEach-Object {$myOutput += "`n" + $_.name ;Get-ADGroupMember $_} | ForEach-Object{if($_.objectClass -eq 'user'){$myOutput += $_.name}else{write-host $_; nestedGroup($_)}}
$myOutput |  Out-File C:\temp\UMMAGroups.csv
