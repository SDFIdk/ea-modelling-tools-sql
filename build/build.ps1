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

Write-Host "Building MDG"
$currentDirectory = Get-Location
$mdgFileName = "mdg_eamt_sql.xml"
$searchesFileName = "ea_search.xml"
java -jar $saxonJar -xsl:build\combine_ea_searches_mdg.xsl -it:"start-template" -o:target\$mdgFileName folderPath=$currentDirectory\src version=$mdgVersion
Write-Host "Building searches for import in My Searches"
java -jar $saxonJar -xsl:build\combine_ea_searches_import_export.xsl -it:"start-template" -o:target\$searchesFileName folderPath=$currentDirectory\src
Write-Host "Building documentation"
java -jar $saxonJar -xsl:build\combine_ea_searches_documentation.xsl -it:"start-template" -o:target\ea_search_doc.xhtml folderPath=$currentDirectory\src mdgFileName=$mdgFileName searchesFileName=$searchesFileName
Write-Host "Finished"