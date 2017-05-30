Import-Module activedirectory
$Servername = Read-Host 'Server name'
$Readpassword = Read-Host 'Password'
$Domain = Read-Host 'Domain'
$DC1,$DC2 = $Domain.Split('.')
$OUend = "DC=$DC1,DC=$DC2"
echo "DC = $OUend"
$Path1 = Read-Host 'CSV file name | ____.CSV'
$ADUsers = Import-Csv .\$Path1 -Encoding UTF8
foreach ($User in $ADUsers)
{
    $Firstnamepre = $User.firstname
    $Firstname = $Firstnamepre -replace '\s','-' -replace 'æ','e' -replace 'ø','o' -replace 'å','a'
    $Lastnamepre = $User.lastname
    $Lastname = $Lastnamepre -replace '\s','-' -replace 'æ','e' -replace 'ø','o' -replace 'å','a'
    $Department = $User.department
    if ($Office) {
    $Office = $User.office
    } else { $Office = ''}
    $Birthdate = $User."birthday (ISO 8601)"
    $Birthdate1 = "$Birthdate3"+"$Birthdate2"
    $Birthdate2 = $User."birthday (ISO 8601)".Substring(5,2)
    $Birthdate3 = $Birthdate.substring(8,2)
    $Username = $Firstname.ToLower().substring(0,2)+'.'+$Lastname.ToLower().substring(0,2)+$Birthdate1 -replace '\s','-'
    $OU = $User.department
    $Password = $Readpassword
    if (Get-ADUser -F {SamAccountName -eq $Username})
    {
        Write-Warning "The user '$Username' already exists, skipping..."
    }
    else
    {
        if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq 'ou=$Department,$OUend'")
        {
#            Write-Warning "OU '$Department' already exists, skipping..."
        }
        else
        {
            New-ADOrganizationalUnit -Name $Department -ProtectedFromAccidentalDeletion $false -Description "$Domain"
        }
            If (Get-ADGroup -Filter {SamAccountName -eq $Department})
        {
#            Write-Warning "Group '$Department' already exists, skipping..."
        }
        else
        {
           New-ADGroup -GroupScope Global -Name $Department 
        }
        echo $Username
        New-ADUser `
        -SamAccountName $Username `
        -Name "$Firstnamepre $Lastnamepre" `
        -GivenName $Firstnamepre `
        -Surname $Lastnamepre `
        -Enabled $True `
        -DisplayName "$Firstnamepre $Lastnamepre" `
        -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
        -Department $Department `
        -UserPrincipalName $Username@$Domain `
        -Path "OU=$department,$OUend" `
        -Description "$Department" `
        -Office "$Office" `
        -ChangePasswordAtLogon $True
    }
    Add-ADGroupMember -Identity $Department -Members $Username  |Out-Null
}