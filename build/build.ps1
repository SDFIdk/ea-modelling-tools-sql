# Windows PowerShell script to create the HTML file.
# saxonJar is the location of the Saxon jar file
param(
    [Parameter(Mandatory=$true)] [string]$MdgVersion
)

# change to UTF-8
chcp 65001

# Check whether SAXON_CP environment variable is set. SAXON_CP has to point to the main jar file in the Saxon distribution, see https://www.saxonica.com.
if (-not $env:SAXON_CP) {
    Write-Error "The environment variable SAXON_CP is not set. Script will exit."
    exit 1
} else {
    Write-Host "SAXON_CP=$env:SAXON_CP"
}

$Folder = "target"
if (Test-Path $Folder) {
    Remove-Item -Recurse $Folder
    Write-Host "INFO Deleted folder $Folder"
    New-Item $Folder -ItemType Directory
    Write-Host "INFO Folder $Folder created successfully"
}

Write-Host "INFO Building MDG"

$CurrentDirectory = Get-Location
$MdgFileName = "mdg_eamt_sql.xml"
$SearchesFileName = "ea_search.xml"
$ViewsFileName = "ea_modelviews.xml"

$Java = Join-Path $env:JAVA_HOME "bin/java.exe"

& $Java `
    -cp $env:SAXON_CP `
    net.sf.saxon.Transform `
    -xsl:build/combine_ea_searches_mdg.xsl `
    -it:"start-template" `
    -o:target/$MdgFileName `
    folderPath=$CurrentDirectory/src `
    version=$MdgVersion

Write-Host "INFO Building (editable) searches"
& $Java `
    -cp $env:SAXON_CP `
    net.sf.saxon.Transform `
    -xsl:build/combine_ea_searches_import_export.xsl `
    -it:"start-template" `
    -o:target/$SearchesFileName `
    folderPath=$CurrentDirectory/src

Write-Host "INFO Copying (editable) model views"
Copy-Item $CurrentDirectory/src/modelviews/modelviews.xml -Destination $CurrentDirectory/target/$ViewsFileName
(Get-Item $CurrentDirectory/target/ea_modelviews.xml).LastWriteTime = (Get-Date)
(Get-Item $CurrentDirectory/target/ea_modelviews.xml).CreationTime = (Get-Date)

Write-Host "INFO Building documentation"
& $Java `
    -cp $env:SAXON_CP `
    net.sf.saxon.Transform `
    -s:target/$MdgFileName `
    -xsl:build/create_mdg_documentation.xsl `
    -it:"start-template" `
    -o:target/index.html `
    folderPath=$CurrentDirectory/src `
    version=$MdgVersion `
    mdgFileName=$MdgFileName `
    searchesFileName=$SearchesFileName `
    viewsFileName=$ViewsFileName

Write-Host "INFO Finished"