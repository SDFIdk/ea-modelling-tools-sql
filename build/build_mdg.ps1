# Windows PowerShell script to create the HTML file.
# saxonJar is the location of the Saxon jar file
param([Parameter(Mandatory=$true)] $mdgVersion, [Parameter(Mandatory=$true)] $saxonJar)

# change to unicode
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$folder = "..\target"
if (Test-Path $folder) {
	Remove-Item -Recurse $folder
    Write-Host "Deleted folder " + $folder
	New-Item $folder -ItemType Directory
	Write-Host "Folder " + $folder + " created successfully"
}

Write-Host "Running Saxon"
$currentDirectory = Get-Location
java -jar $saxonJar -xsl:build\combine_ea_searches_mdg.xsl -it:"start-template" -o:target\mdg_eamt_sql.xml folderPath=$currentDirectory\src version=$mdgVersion
Write-Host "Finished"