#ALWAYS BACKUP BEFORE RUNNING THIS TOOL

#Tool to import users from a .csv file into Active Directory (firstname, lastname, department)
#Written by Magnus K. Kronberg
$host.ui.RawUI.WindowTitle = "CSVImport | Magnus K. Kronberg"
clear
write "CSVImport | Magnus K. Kronberg"
write " "
write " "
Import-Module activedirectory
#Set variables
$servername = Read-Host 'Server name'
$Password1 = Read-Host 'Password'
$SAMend = Read-Host 'Full domain name'
$path1 = Read-Host 'CSV file name'
$ADUsers = import-csv .\$path1.csv -Encoding UTF8
#Apply variables
foreach ($User in $ADUsers)
{
	$Firstname	= $User.firstname
	$Lastname	= $User.lastname
	$Department	= $User.department
	$Username	= $Firstname.ToLower()+'.'+$Lastname.ToLower()
	$OU			= $User.department
	$Password	= $Password1
#See if user already exists (By username)
	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		Write-Warning "The user '$Username' already exists, skipping..."
	}
	else
    {
#Create new user and user folder.
        mkdir D:\Users\$Username
		New-ADUser `
			-SamAccountName $Username `
			-Name "$Firstname $Lastname" `
			-GivenName $Firstname `
			-Surname $Lastname `
			-Enabled $True `
			-DisplayName "$Firstname $Lastname" `
			-AccountPassword (convertto-securestring $Password -AsPlainText -Force) `
            -Department $Department `
            -UserPrincipalName $Username@$SAMend `
            -HomeDirectory \\$servername\Users `
            -PasswordNeverExpires $True
	}
#Revoke all permissions, this hides the user folder for all other users
    icacls D:\Users\$Username /inheritance:r > $NULL
#Give the user access to the folder
    icacls D:\Users\$Username /grant "${Username}:(OI)(CI)F" | Out-Null
#Give all administrators easy access
    icacls D:\Users\$Username --% /grant Administrators:(OI)(CI)F /T | out-null
}
#Check if the common folder for all employees exists, if not it will create it. (named 'Everyone')
if(!(Test-Path -Path D:\Users\Everyone )){
    mkdir D:\Users\Everyone > $NULL
}
#Give all users access to the common folder
cacls D:\Users\Everyone /E /G Everyone:C > $NULL
#Some self promotion at the end
write " "
write " "
write "CSVImport | Magnus K. Kronberg"
write " "
write " "
Write "Done!"
Write-Host "Press any key to exit"
