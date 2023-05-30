# EA Modelling Tools SQL

## Overview

This repository contains searches in the form of SQL queries that have 
been exported individually using Enterprise Architect (EA). This makes 
it easier to version control them and collaborate with others to further
develop the query collection.

## Installation

The first option is to import the EA Modelling Tools SQL MDG Technology 
(mdg_eamt_sql.xml). With this option, the searches are not editable. 
Import this file if you only want to use the searches. See the 
[EA User Guide for how to import an MDG Technology](https://sparxsystems.com/search/sphider/search.php?query=%22import+mdg+technologies%22&catid=22&search=1&tab=1).

<!-- catid=22 : Shows results for EA User Guide version 16.1 -->

The second option is to import the searches so they appear under "My 
Searches" in EA (ea_search.xml). With this option, the searches are 
editable. This option is used if you want to modify the searches and 
update them in this repository. See the 
[EA User Guide for how to import searches](https://sparxsystems.com/search/sphider/search.php?query=%22model%20search%22&catid=22&search=1&tab=1).

## Usage

Access the search functionality by pressing <kbd>Ctrl</kbd> + 
<kbd>F</kbd>.

Sparx Systems has published a video about model searches, watch it
[here](https://sparxsystems.com/resources/show-video.html?video=gettingstarted-modelsearchbasics).

The model searches in this repository are searches that are not based on
 the Query Builder, but on the SQL Editor. See the [section Model Search in
 the EA User Guide](https://sparxsystems.com/search/sphider/search.php?query=%22model%20search%22&catid=22&search=1&tab=1).
 
The queries in this repository have been tested with .qea file 
repositories, which are based on [SQLite](https://sqlite.org/).

## Writing new queries

EA allows the use of macros (`#xxx`) in the `WHERE` part of SQL queries,
 so that the same search can be used by different people in different 
environments. The `#DB=<DBNAME>#` macro only uses the section of code 
between two matching `#DB=<DBNAME>#` macros if the current database 
type matches the specified `DBNAME`. It can be used where a section of 
the SQL might require special handling depending upon the current 
database type. This functionality can be used to add some text that will
 be not be executed by using a dummy name, e.g. `COMMENT`. This macro 
must be used in the <em>end</em> of the query, not in the beginning.

```sql
select * from t_object;
#DB=COMMENT# This is a comment #DB=COMMENT#
```

See the section
[Create Search Definitions in the EA User Guide](https://www.sparxsystems.com/search/sphider/search.php?query=%22Create+Search+Definitions%22&catid=22&tab=1&search=1)
for more information.

## Building

Run the [Powershell](https://learn.microsoft.com/en-us/powershell/) 
scripts from directory `ea-modelling-tools-sql`, not from directory 
`build`.

```PowerShell
.\build\build.ps1 -saxonJar:"C:\path\to\saxon-he-x.y.jar" -mdgVersion:a.b.c
```

The scripts are combined into three files:

1. an MDG Technology (mdg_eamt_sql.xml);
2. a file containing the searches, following the same structure as in 
searches exported from EA and as in C:\Users\<username>\AppData\Roaming\Sparx Systems\EA\Search Data\EA_Search.xml
(ea_search.xml);
3. an HTML file listing all the searches and their comments 
(ea_search_doc.xhtml).
