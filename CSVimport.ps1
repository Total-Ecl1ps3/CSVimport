[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "CSVImport v3 | Magnus K. Kronberg"
clear
write "CSVImport v3 | Magnus K. Kronberg"
write " "
write " "
Import-Module activedirectory
$servername = Read-Host 'Server name'
$Password1 = Read-Host 'Password'
$SAMend = Read-Host 'Full domain name'
$OUend = Read-Host 'OU Parent path (DC=______,DC=_______)'
$path1 = Read-Host 'CSV file name'
$ADUsers = import-csv .\$path1.csv -Encoding UTF8
foreach ($User in $ADUsers)
{
	$Firstname	= $User.firstname
	$Lastname	= $User.lastname
	$Department	= $User.department
	$Username	= $Firstname.ToLower()+'.'+$Lastname.ToLower()
	$OU			= $User.department
	$Password	= $Password1
    if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		Write-Warning "The user '$Username' already exists, skipping..."
	}
	else
    {
        mkdir D:\Users\$Username
        if(!(Test-Path -Path D:\Users\$Department )){
            mkdir D:\Users\$Department > $NULL
            icacls D:\Users\$Department /inheritance:r > $NULL
        }
        if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq 'ou=$Department,$OUend'")
        {
#        Write-Warning "OU '$Department' already exists, skipping..."
        }
        else
        {
        New-ADOrganizationalUnit -Name $Department
        }
        If (Get-ADGroup -Filter {SamAccountName -eq $Department})
        {
#        Write-Warning "Group '$Department' already exists, skipping..."
        }
        else
        {
        New-ADGroup -GroupScope Global -Name $Department | Out-Null
        }
		New-ADUser `
			-SamAccountName $Username `
			-Name "$Firstname $Lastname" `
			-GivenName $Firstname `
			-Surname $Lastname `
			-Enabled $True `
			-DisplayName "$Firstname $Lastname" `
			-AccountPassword (convertto-securestring $Password -AsPlainText -Force) `
            -Department $Department `
            -Path "ou=$Department,$OUend" `
            -UserPrincipalName $Username@$SAMend `
            -HomeDirectory \\$servername\Users `
            -ChangePasswordAtLogon $True
	}
    Add-ADGroupMember -Identity $Department -Members $Username
    icacls D:\Users\$Username /inheritance:r > $NULL
    icacls D:\Users\$Username /grant "${Username}:(OI)(CI)F" | Out-Null
    icacls D:\Users\$Department /inheritance:r > $NULL
    icacls D:\Users\$Department /grant "${Department}:(OI)(CI)F" | Out-Null
}
if(!(Test-Path -Path D:\Users\Everyone )){
    mkdir D:\Users\Everyone > $NULL
}
cacls D:\Users\Everyone /E /G Everyone:C > $NULL
write " "
write " "
write "CSVImport v3 | Magnus K. Kronberg"
write " "
write " "
Write "Done!"