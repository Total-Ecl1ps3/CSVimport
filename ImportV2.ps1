#ALWAYS BACKUP BEFORE RUNNING THIS TOOL

#Verktøy for importering av brukere inn i Active Directory fra CSV fil (firstname, lastname, department)
#Laget av Magnus K. Kronberg
$host.ui.RawUI.WindowTitle = "CSVImport | Magnus K. Kronberg"
clear
write "CSVImport | Magnus K. Kronberg"
write " "
write " "
Import-Module activedirectory
#Sett instillinger
$servername = Read-Host 'Server name'
$Password1 = Read-Host 'Password'
$SAMend = Read-Host 'Full domain name'
$path1 = Read-Host 'CSV file name'
$ADUsers = import-csv .\$path1.csv -Encoding UTF8
#Aktiver instillingene
foreach ($User in $ADUsers)
{
	$Firstname	= $User.firstname
	$Lastname	= $User.lastname
	$Department	= $User.department
	$Username	= $Firstname.ToLower()+'.'+$Lastname.ToLower()
	$OU			= $User.department
	$Password	= $Password1
#Se om bruker allerede finnes
	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		Write-Warning "The user '$Username' already exists, skipping..."
	}
	else
    {
#Lag nye brukere og brukermappe på serveren
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
#Ikke tillat andre brukere å se i brukermappen
    icacls D:\Users\$Username /inheritance:r > $NULL
#Gi brukeren tillgang til sin egen mappe
    icacls D:\Users\$Username /grant "${Username}:(OI)(CI)F" | Out-Null
#Gi tillgang til Administratorer
    icacls D:\Users\$Username --% /grant Administrators:(OI)(CI)F /T | out-null
}
#Lag fellesmappe
if(!(Test-Path -Path D:\Users\Felles )){
    mkdir D:\Users\Felles > $NULL
}
#Gi alle tilgang til fellesmappen
cacls D:\Users\Felles /E /G Everyone:C > $NULL
write " "
write " "
write "CSVImport | Magnus K. Kronberg"
write " "
write " "
Write "Done!"
Write-Host "Press any key to exit"