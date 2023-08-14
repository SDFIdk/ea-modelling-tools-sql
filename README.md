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

### Formatting

The formatting of the queries is not important when running a search 
from the "Find in Project" tab. However, the formatting is important
when the queries are supposed to be reused in, for example, the 
creation of search folders in the
[Model Views tab](https://sparxsystems.com/search/sphider/search.php?query=%22model+views%22&catid=22&search=1&tab=1)
or the
[creation of model documents](https://sparxsystems.com/search/sphider/search.php?query=%22create+model+document%22&catid=22&search=1&tab=1).

In those cases, the query must include the **case sensitive** phrase
`ea_guid AS CLASSGUID` and the object type (using the alias `CLASSTYPE`).
Therefore, the queries are formatted with upper case keywords.

EA provides no functionality to format queries, this can be done with
a dedicated database tool.

### Column CLASSGUID

The query must include the phrase `ea_guid AS CLASSGUID` so that you can
  right-click on the results and, for example, have access to finding 
the model element in the Project Browser.

`CLASSGUID` is not shown as a column in the results.

See the section
[Create Search Definitions in the EA User Guide](https://www.sparxsystems.com/search/sphider/search.php?query=%22Create+Search+Definitions%22&catid=22&tab=1&search=1)
for more information.

### Column CLASSTYPE

The query must include the phrase `<classtype> AS CLASSTYPE` so that an 
icon can be displayed for the model element. Possible values for 
`<classtype>` are shown in the table below.

| Table | CLASSTYPE | Icon | Comment |
|---|---|---|---|
| t_package | 'Package' | ![package](http://demo.sparxpublic.com/images/element64/package.png "package") |  |
| t_object | t_object.object_type | Depends on `object_type`:<br />![class](http://demo.sparxpublic.com/images/element64/class.png "class")<br />![data type](http://demo.sparxpublic.com/images/element64/datatype.png "data type")<br />![enumeration](http://demo.sparxpublic.com/images/element64/enumeration.png "enumeration")<br />…|  |
| t_attribute | 'Attribute' | ![attribute](http://demo.sparxpublic.com/images/element64/attribute.png) |  |
| t_connector | t_connector.connector_type | Depends on `connector_type`:<br />![association](http://demo.sparxpublic.com/images/element64/association.png "association")<br />![generalization](http://demo.sparxpublic.com/images/element64/generalization.png "generalization")<br />![aggregation](http://demo.sparxpublic.com/images/element64/aggregation.png "aggregation or composition")<br />… | Connector ends are not stand-alone objects in EA. Use `t_connector.connector_type` when the focus is on the connector itself. |
| t_connector | 'AssociationEnd' | ![association end](http://demo.sparxpublic.com/images/element64/associationend.png "association end") | Connector ends are not stand-alone objects in EA. Use `AssociationEnd` when the connector is an association (including aggregations and compositions) and when the focus is on the association end. |
| t_diagram | t_diagram.diagram_type | ![diagram](http://demo.sparxpublic.com/images/element64/diagram.png "diagram") |  |

`CLASSTYPE` is not shown as a column in the results.

See the section
[Create Search Definitions in the EA User Guide](https://www.sparxsystems.com/search/sphider/search.php?query=%22Create+Search+Definitions%22&catid=22&tab=1&search=1)
for more information.

### Column CLASSTABLE

In queries for connectors and diagrams, the phrase 
`<classtable> AS CLASSTABLE` must be included in order for the right 
icon to be displayed.

| Table | CLASSTABLE |
|---|---|
| t_connector | 't_connector' |
| t_diagram | 't_diagram' |

`CLASSTABLE` is not shown as a column in the results.

See the section
[Create Search Definitions in the EA User Guide](https://www.sparxsystems.com/search/sphider/search.php?query=%22Create+Search+Definitions%22&catid=22&tab=1&search=1)
for more information.

### Writing comments

EA allows the use of macros (`#xxx`) in the `WHERE` part of SQL queries,
 so that the same search can be used by different people in different 
environments. The `#DB=<DBNAME>#` macro only uses the section of code 
between two matching `#DB=<DBNAME>#` macros if the current database 
type matches the specified `DBNAME`. It can be used where a section of 
the SQL might require special handling depending upon the current 
database type. This functionality can be used to add some text that will
 be not be executed by using a dummy name, e.g. `COMMENT`. This macro 
must be used in the **end** of the query, not in the beginning.

```sql
SELECT
    o.ea_guid AS CLASSGUID,
    o.object_type AS CLASSTYPE,
    o.*
FROM
    t_object o;
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
