Import-Module activedirectory
echo "Server domain:"
(Get-WmiObject Win32_computerSystem).Domain
Echo "Server name:"
(Get-WmiObject Win32_computerSystem).Name
$Servername = (Get-WmiObject Win32_computerSystem).Name
$Readpassword = Read-Host 'Password'
$Domain = (Get-WmiObject Win32_computerSystem).Domain
$DC1,$DC2 = $Domain.Split('.')
$OUend = "DC=$DC1,DC=$DC2"
echo "DC = $OUend"
Add-type -AssemblyName System.windows.forms

$Path = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Filter = 'CSV files (*.csv)|*.csv'  
    }
$null = $path.ShowDialog()
$Path1 = $path.FileName
echo "CSV file:"
$path1
$ADUsers = Import-Csv $Path1 -Encoding UTF8
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
    $Birthdate = $User."birthday"
    $Birthdate2 = $User."birthday".Substring(5,2)
    $Birthdate3 = $Birthdate.substring(8,2)
    $Birthdate1 = "$Birthdate3"+"$Birthdate2"
    $Username = $Firstname.ToLower().substring(0,2)+'.'+$Lastname.ToLower().substring(0,2)+$Birthdate1 -replace '\s','-'
    $OU = $User.department
    $Password = $Readpassword
    if (Get-ADUser -F {SamAccountName -eq $Username})
    {
        Write-Warning "The user '$Username' already exists, skipping..."
    }
    else
    {
        mkdir D:\Users\$Username
        if(!(Test-Path -Path D:\Users\$Department ))
        {
            mkdir D:\Users\$Department > $NULL
            icacls D:\Users\$Department /inheritance:r > $NULL
        }
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
        -HomeDirectory \\$servername\Users `
        -Description "$Department" `
        -Office "$Office" `
        -ChangePasswordAtLogon $True
    }
    Add-ADGroupMember -Identity $Department -Members $Username  |Out-Null
    icacls D:\Users\$Username /inheritance:r |Out-Null
    icacls D:\Users\$Username /grant "${Username}:(OI)(CI)F" |Out-Null
    icacls D:\Users\$Department /inheritance:r |Out-Null
    icacls D:\Users\$Department /grant "${Department}:(OI)(CI)F" |Out-Null
}
if(!(Test-Path -Path D:\Users\Everyone )){
    mkdir D:\Users\Everyone |Out-Null
}
cacls D:\Users\Everyone /E /G Everyone:C  
