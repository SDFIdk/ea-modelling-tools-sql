# Windows PowerShell script to create the HTML file.
# saxonJar is the location of the Saxon jar file
# IMPORTANT Run this script from the parent directory (ea-modelling-tools-sql) of the directory this script is in (build)
param([Parameter(Mandatory=$true)] $saxonJar)

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
java -jar $saxonJar -xsl:build\combine_ea_searches_import_export.xsl -it:"start-template" -o:target\ea_search.xml folderPath=$currentDirectory\src
Write-Host "Finished"