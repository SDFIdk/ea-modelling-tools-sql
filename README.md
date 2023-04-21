# EA Modelling Tools SQL

## Overview

This repository contains searches in the form of SQL queries, that have 
been exported individually using Enterprise Architect (EA). This makes 
it easier to version control them and collabate with others to further
develop the query collection.

## Installation

The first option is to import the EA Modelling Tools SQL MDG Technology.
 The searches are then not editable. Import this file if you only want
 to use the searches.

The second option is to import the searches so they
 appear under "My Searches" in EA. The searches are then editable. This 
file is used if you want to modify the searches and update them in this 
repository.

See the section on Model Search in the EA User Guide for how to 
import searches, and the section on MDG Technologies for how
to import an MDG Technology.

## Usage

You can access the search functionality by pressing Ctrl+F.

Sparx Systems has published a video about model searches, find it
[here](https://sparxsystems.com/resources/show-video.html?video=gettingstarted-modelsearchbasics).

The model searches in this repository are searches that are not based on
 the Query Builder, but on the SQL Editor, see the section Model Search in
 the EA user guide for more information.
 
The queries in this repository have been tested with .qea file 
repositories, which are based on SQLite.

## Writing new queries

EA allows the use of macros (`#xxx`) in the `WHERE` part of SQL queries,
 so that the same search can be used by different people in different 
environments. The `#DB=<DBNAME>#` macro only uses the section of code 
between two matching `#DB=<DBNAME>#` macros if the current database 
type matches the specified `DBNAME`. It can be used where a section of 
the SQL might require special handling depending upon the current 
database type. This functionality can be used to add some text that will
 be not be executed by using a dummy name, e.g. `COMMENT`. This macro 
must be used in the *end* of the query, not in the beginning.

```sql
select * from t_object;
#DB=COMMENT# This is a comment #DB=COMMENT#
```

See the section Create Search  Definitions in the EA user guide for more
information.

## Building

Run the [Powershell](https://learn.microsoft.com/en-us/powershell/) 
scripts from directory `ea-modelling-tools-sql`, not from directory 
`build`.

```PowerShell
.\build\build.ps1 -saxonJar:"C:\path\to\saxon-he-x.y.jar" -mdgVersion:a.b.c
```

The scripts are combined into three files:

1. an MDG Technology;
2. a file containg the searches, following the same structure as in 
searches exported from EA and as in C:\Users\<username>;
\AppData\Roaming\Sparx Systems\EA\Search Data\EA_Search.xml
3. an HTML file listing all the searches and 
their comments.
