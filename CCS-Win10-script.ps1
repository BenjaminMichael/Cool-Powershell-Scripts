#This Script Creates AD Global Security Groups (if they dont exist) for All OUs below 'CCS-Win10'
#then it adds computers in those OUs to the group for that OU
#and if its in a group for one of the other OUs it takes it out but it is important to never delete the proper group
#(this would cause a momentary loss of the role based software provisioning
#that these groups correspond to)
#
#There is an error check to see if the total number of OUs matches the number of OUs we modify.
#If it logs an error then you probably have OUs more than 4 levels deep.
#


function makeGroupsAndAddComputers(){


    $myLogData ="$(Get-Date) `r`n"
    $global:computersAddedToEucAASitesPC = 0
    $global:computersThatHaveChanged = 0


    function shortenNames($myParam){
        switch ($myParam)
        {
            "athletics"  {$newName = "Ath"}
            "classroom"  {$newName = "Class"}
            "classrooms"  {$newName = "Class"}
            "communication studies" {$newName = "commstudies"}
            "ford school" {$newName = "Ford"}
            "ITS VDI Images" {$newName = "VDI"}
            "kinesiology" {$newName = "Kines"}
            "library" {$newName = "Lib"}
            "medical school" {$newName = "medschool"}
            "Observatory Lodge classroom" {$newName = "KinesLodge"}
            "pharmacy" {$newName = "Phar"}
            "virtual sites" {$newName = "VSites"}

            default {$newName = $myParam}
        }

    return $newName
    }

    function checkIfMemberAddIfNot{

    param ([string]$ouObject, [string]$targetGroup, $changedCPUCount)
    #
    #This function takes in 3 parameters:
    # ouObject is an OU that we check to see if any computers in that OU (searchscope one level) are not in the target group and if not we add them
    # targetGroup is the group we expect to see
    # changedCPUCount is a variable for tracking how many changes we make throughout the entire lifecycle of makeGroupsAndAddComputers()

    #
    #Check to see if our targetGroup exists and if not we create it
    #
    try{$myGroupCheck = Get-ADGroup $targetGroup}catch{if($_.Exception.Message -like "Cannot find object*"){New-ADGroup -Name $targetGroup -GroupCategory Security -GroupScope Global -Path "OU=Sites,OU=AppsAnywhere,OU=ComputerGroups,OU=Groups,OU=EUC,OU=Products,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu" }}

    #
    #group check and correct old incorrect groups (never remove the correct group)
    #
    $listOfComputer=@()
    Get-ADComputer -SearchBase $ouObject -SearchScope OneLevel -filter {name -like "S-*"} -properties Name, MemberOf | ForEach-Object {$myMemberz=$_.memberOf;$numberofMemberz = $myMemberz.count;for($i=0;$i -lt $numberofMemberz;$i++){Add-ADGroupMember -Identity $targetGroup -Members $_;if((!$myMemberz[$i].contains($targetGroup)) -and ($myMemberz[$i] -ilike "CN=euc-aa-site-*")){Remove-ADGroupMember -identity $myMemberz[$i] -Members $_ -Confirm:$false;$global:computersThatHaveChanged++}} }

    #
    #Next we will see if they are in euc-aa-sites-allPc, add them if they are not and make a note of it in the logs.
    #
    Get-ADComputer -SearchBase $ouObject -SearchScope OneLevel -filter {name -like "S-*"} -Properties memberOf | ForEach-Object {if ($_.memberOf -ilike "*euc-aa-Sites-PC*"){<#do nothing #>}else{add-adgroupmember -Identity "euc-aa-Sites-PC" -Members $_ ;$global:computersAddedToEucAASitesPC++}}

    }

#
# What we are trying to do is run our function checkIfMemberAddIfNot() on all the computers in all the OUs in the
#     CCS-Win10 OU.  In order to run that function you have to pass in the group names which go:
#       "euc-aa-site-$($greatGreatGrandparentName)-$($greatGrandparentName)-$($grandParentName)-$($myParentsName)-$(shortenNames($_.name))"
#      but if a parent, grandparent, etc, is the $sourceOU or $rootOfCCS we don't want to add it to the name.

$sourceOU = "OU=CCS-WIN10,OU=CCS,OU=Computers,OU=EUC,OU=Administration,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"
$rootOfCCS = "OU=CCS,OU=Computers,OU=EUC,OU=Administration,OU=UMICH,DC=adsroot,DC=itcs,DC=umich,DC=edu"

$tempObjArray=@() #holds all child objects

#first we populate the tempObjArray with all the OUs in the win10ccs OU
Get-ADOrganizationalUnit -SearchBase $sourceOU -SearchScope Subtree -filter * | ForEach-Object{$tempObjArray+=$_}


$tempObjArray | ForEach-Object {

    $finalAnswer=@() #had to use two arrays one called finalanswer and then one OUTSIDE this for-each-function called [array]masterGroupList
    $currentAnswer=@()

    #if the object is not null
    if ($_ -ne $null){
        #create a parent
        $myParent = (([adsi]"LDAP://$($_.DistinguishedName)").Parent).Substring(7)
        $getName = Get-ADOrganizationalUnit -SearchBase $myParent -SearchScope Base -filter *
        $myParentsName = $getName.name
        $myParentsName = shortenNames($myParentsName)
            
            #if we are seeing the parent of the root level OR we are seeing root as the parent "euc-aa-site-$($_.name)" ELSE go on to create a grandparent
            if(($myParent -eq $rootOfCCS) -or ($getName.name -eq "CCS-WIN10") ){
                $finalAnswer += "euc-aa-site-$(shortenNames($_.name))"
                $currentAnswer = "euc-aa-site-$(shortenNames($_.name))"
                checkIfMemberAddIfNot $_ $currentAnswer      
                }else
                {
               $grandParent = (([adsi]"LDAP://$($myParent)").Parent).Substring(7)
               $getGPName = Get-ADOrganizationalUnit -SearchBase $grandParent -SearchScope Base -filter *
               $grandParentName = $getGPName.Name
               $grandParentName = shortenNames($grandParentName)
               
                #if the grandparent we just created is the root or the root's parent "euc-aa-site-$($myParentsName)-$($_.name)" ELSE create a greatGrandparent
                if(($grandParent -eq $rootOfCCS) -or ($getGPName.name -eq "CCS-WIN10") )
                {
                  $finalAnswer += "euc-aa-site-$($myParentsName)-$(shortenNames($_.name))"
                  $currentAnswer = "euc-aa-site-$($myParentsName)-$(shortenNames($_.name))"
                  checkIfMemberAddIfNot $_ $currentAnswer
                 }else
                 {           
                  $greatGrandparent =  (([adsi]"LDAP://$($getGPName.DistinguishedName)").Parent).Substring(7)
                  $getGGPName = Get-ADOrganizationalUnit -SearchBase $greatGrandparent -SearchScope Base -filter *
                  $greatGrandparentName = $getGGPName.name
                  $greatGrandparentName = shortenNames($greatGrandparentName)

                   #if the greateGrandparent we just created is the root or the root's paernt
                   if(($greatGrandParent -eq $rootOfCCS) -or ($getGGPName.Name -eq "CCS-WIN10") )
                   {
                    $finalAnswer += "euc-aa-site-$($grandParentName)-$($myParentsName)-$(shortenNames($_.name))"
                    $currentAnswer = "euc-aa-site-$($grandParentName)-$($myParentsName)-$(shortenNames($_.name))"
                    checkIfMemberAddIfNot $_ $currentAnswer
                   }else
                   {
                    $greatGreatGrandparent =  (([adsi]"LDAP://$($getGGPName.DistinguishedName)").Parent).Substring(7)
                    $getGGGPName = Get-ADOrganizationalUnit -SearchBase $greatGreatGrandparent -SearchScope Base -filter *
                    $greatGreatGrandparentName = $getGGGPName.name
                    $greatGreatGrandparentName = shortenNames($greatGreatGrandparentName)
                   
                   if(($greatGreatGrandParent -eq $rootOfCCS) -or ($getGGGPName.Name -eq "CCS-WIN10") )
                   {       
                    $finalAnswer += "euc-aa-site-$($greatGrandparentName)-$($grandParentName)-$($myParentsName)-$(shortenNames($_.name))"
                    $currentAnswer = "euc-aa-site-$($greatGrandparentName)-$($grandParentName)-$($myParentsName)-$(shortenNames($_.name))"
                    checkIfMemberAddIfNot $_ $currentAnswer
                   }else
                   {
                    $finalAnswer += "euc-aa-site-$($greatGreatGrandparentName)-$($greatGrandparentName)-$($grandParentName)-$($myParentsName)-$(shortenNames($_.name))"
                    $currentAnswer ="euc-aa-site-$($greatGreatGrandparentName)-$($greatGrandparentName)-$($grandParentName)-$($myParentsName)-$(shortenNames($_.name))"
                    checkIfMemberAddIfNot $_ $currentAnswer
                   }
                  }   
                 }     
                }
               }
              [array]$masterGroupList += "$($finalAnswer)`r`n"
   }

    #checking for missed OUs
    if($tempObjArray.count -ne $masterGroupList.count){$myLogData += "Debug we did not capture all the OUs.  $($tempObjArray.count) actual objects but only $($masterGroupList.count) group names were created.`r`n"}else{$myLogData += "0 OUs were missed because the tree was too many levels deep :)`r`n" }
    
    #results data:
    $myLogData += "$($global:computersAddedToEucAASitesPC) New Computers added to euc-aa-sites-PC `r`n"
    $myLogData += "$($global:computersThatHaveChanged) Computers moved OUs (New Computers are not counted in this total) `r`n"
    $myLogData += "$($masterGroupList.count) OUs were found in CCS-Win10 `r`n"

    if (Test-Path "C:\Windows\EUC\Log\CCS-Win10Script.log")
    {
        $myLogData | Add-Content "C:\Windows\EUC\Log\CCS-Win10Script.log"}else{
        $myLogData | Out-File "C:\Windows\EUC\Log\CCS-Win10Script.log"
    }
}




$myResults = @()
$masterGroupList=@()

makeGroupsAndAddComputers
