#AD groups difference checker by Jeff Johnston

Clear-Host
$global:users_groups = @{}
$global:allgroups = @()
$global:DoneEnteringGroups = 0

$domain = Get-ADDomain | select-Object DNSRoot | Where-Object {!($_.psiscontainer)} | foreach {$_.DNSRoot}    

Write-Host "- Active Directory Group Differences Checker -" -ForegroundColor white -BackgroundColor darkgreen
Write-Host "Working on domain: $domain" -ForegroundColor green
Write-Host "Use SAM account usernames. Example: jjohns206" -ForegroundColor Yellow

function GetUserGroups($user){
            Write-Host "Attempting to lookup groups for $user" -ForegroundColor green
            $groups = (Get-ADUser $user -Properties MemberOf).memberof | Get-ADGroup | Select-Object name | Where-Object {!($_.psiscontainer)} | foreach {$_.name}    
            Foreach ($group in $groups) {
                if (!($global:allgroups -contains $group)) {
                    $global:allgroups += $group
                }
            }
            $global:users_groups.Add($user, $groups)
            Write-Host "$($groups.Count) groups found for $user" -ForegroundColor yellow
}

while($DoneEnteringGroups -eq 0) {
    $user = Read-Host "Enter Username [Enter when done]"
    If ($user.length -eq 0 -And $users_groups.Count -lt 2) {
        Write-Host "You must enter at least 2 valid users to make a comparison." -ForegroundColor white -BackgroundColor darkred
        Write-Host $users
    }
    ElseIf ($user.length -eq 0 -And $users_groups.Count -gt 1) {
        $DoneEnteringGroups = 1
        }
    Else {
        try {
            GetUserGroups $user
        }
        catch {
            Write-Host "Error looking up $user. Please enter a valid SAM Account name" -ForegroundColor white -BackgroundColor darkred
        }
    }
}

Clear-Host
Write-Host "$($allgroups.Count) groups found among $($users_groups.Count) user accounts.`n" -ForegroundColor green

# Create an empty array to store the formatted output
$output = @()

Foreach ($user in $users_groups.GetEnumerator() ) {
    $username = $user.Name
    $usergroups = $user.Value | Where-Object {$allgroups -notcontains $_}

    # Create a custom object with properties for username and groups
    $result = [PSCustomObject]@{
        Username = $username
        Groups = $usergroups -join ', '
    }

    # Add the custom object to the output array
    $output += $result
}

# Display the formatted output with columns
$output | Format-Table -AutoSize -Property Username, Groups

$ExportQuestion = Read-Host "Enter 'E' to export results to file or ENTER to quit"

IF ($ExportQuestion -eq "E") {
    Foreach ($user in $users_groups.GetEnumerator() ) {
        Add-Content ADGroupDifOutExport.txt "---- $($user.Name) does not have the following groups:`n"
        Foreach ($group in $allgroups) {
            if (!($user.Value -contains $group)) {
                Add-Content ADGroupDifOutExport.txt "  $group"
                }
        }
        Add-Content ADGroupDifOutExport.txt "`n"
    }
    Write-Host "Results exported to ADGroupDifOutExport.txt in the current directory." -ForegroundColor green
    Write-Host "Press ENTER to exit"
    Read-Host
}
Else {
    Write-Host "Have a nice day!"
}
