# Windows PowerShell script to create the HTML file.
# saxonJar is the location of the Saxon jar file
param([Parameter(Mandatory=$true)] $mdgVersion)

# change to unicode
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Check whether SAXON_CP user environment variable is set
if ([System.Environment]::GetEnvironmentVariable("SAXON_CP", [System.EnvironmentVariableTarget]::User) -eq $null) {
    Write-Host "The user environment variable SAXON_CP is not set. Script will exit."
    exit
}

$folder = "target"
if (Test-Path $folder) {
	Remove-Item -Recurse $folder
    Write-Host "INFO Deleted folder "$folder
	New-Item $folder -ItemType Directory
	Write-Host "INFO Folder "$folder" created successfully"
}

Write-Host "INFO Using Saxon (SAXON_CP="$env:SAXON_CP")"
Write-Host "INFO Building MDG"
$currentDirectory = Get-Location
$mdgFileName = "mdg_eamt_sql.xml"
$searchesFileName = "ea_search.xml"
$viewsFileName = "ea_modelviews.xml"
java -cp $env:SAXON_CP net.sf.saxon.Transform -xsl:build\combine_ea_searches_mdg.xsl -it:"start-template" -o:target\$mdgFileName folderPath=$currentDirectory\src version=$mdgVersion
Write-Host "INFO Building (editable) searches"
java -cp $env:SAXON_CP net.sf.saxon.Transform -xsl:build\combine_ea_searches_import_export.xsl -it:"start-template" -o:target\$searchesFileName folderPath=$currentDirectory\src
Write-Host "INFO Copying (editable) model views"
Copy-Item $currentDirectory\src\modelviews\modelviews.xml -Destination $currentDirectory\target\$viewsFileName
(Get-Item $currentDirectory\target\ea_modelviews.xml).LastWriteTime = (Get-Date)
(Get-Item $currentDirectory\target\ea_modelviews.xml).CreationTime = (Get-Date)
Write-Host "INFO Building documentation"
java -cp $env:SAXON_CP net.sf.saxon.Transform -xsl:build\create_mdg_documentation.xsl -s:target\$mdgFileName -it:"start-template" -o:target\ea_search_doc.xhtml folderPath=$currentDirectory\src mdgFileName=$mdgFileName searchesFileName=$searchesFileName viewsFileName=$viewsFileName
Write-Host "INFO Finished"