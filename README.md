# EA Modelling Tools SQL

This repository contains searches that have been exported individually 
using Enterprise Architect (EA). See also the section on Model Search
in the EA User Guide.

## Building

The scripts can be combined into a file for sharing.

One option is to build a file that can be used to import the searches so
 they appear under "My Searches" in EA. The searches are then editable.

A second option is to bundle the searches in an MDG. The searches are 
then not editable.

Run the [Powershell](https://learn.microsoft.com/en-us/powershell/) 
scripts from directory `ea-modelling-tools-sql`, not from directory 
`build`.

```PowerShell
.\build\build_import_export.ps1 -saxonJar:"C:\path\to\saxon-he-x.y.jar"
```

```PowerShell
.\build\build_mdg.ps1 -saxonJar:"C:\path\to\saxon-he-x.y.jar" -mdgVersion:a.b.c
```
