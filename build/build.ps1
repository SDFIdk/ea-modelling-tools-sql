# Windows PowerShell script to create the HTML file.
# saxonJar is the location of the Saxon jar file
param([Parameter(Mandatory=$true)] $saxonJar, [Parameter(Mandatory=$true)] $mdgVersion)

# change to unicode
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$folder = "target"
if (Test-Path $folder) {
	Remove-Item -Recurse $folder
    Write-Host "INFO Deleted folder " $folder
	New-Item $folder -ItemType Directory
	Write-Host "INFO Folder "$folder" created successfully"
}

Write-Host "INFO Building MDG"
$currentDirectory = Get-Location
$mdgFileName = "mdg_eamt_sql.xml"
$searchesFileName = "ea_search.xml"
$viewFileName = "ea_modelviews.xml"
java -jar $saxonJar -xsl:build\combine_ea_searches_mdg.xsl -it:"start-template" -o:target\$mdgFileName folderPath=$currentDirectory\src version=$mdgVersion
Write-Host "INFO Building (editable) searches"
java -jar $saxonJar -xsl:build\combine_ea_searches_import_export.xsl -it:"start-template" -o:target\$searchesFileName folderPath=$currentDirectory\src
Write-Host "INFO Copying (editable) model views"
Copy-Item $currentDirectory\src\modelviews\modelviews.xml -Destination $currentDirectory\target\$viewFileName
(Get-Item $currentDirectory\target\ea_modelviews.xml).LastWriteTime = (Get-Date)
(Get-Item $currentDirectory\target\ea_modelviews.xml).CreationTime = (Get-Date)
Write-Host "INFO Building documentation"
java -jar $saxonJar -xsl:build\create_mdg_documentation.xsl -s:target\$mdgFileName -it:"start-template" -o:target\ea_search_doc.xhtml folderPath=$currentDirectory\src mdgFileName=$mdgFileName searchesFileName=$searchesFileName
Write-Host "INFO Finished"