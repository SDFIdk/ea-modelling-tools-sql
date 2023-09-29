# EA Modelling Tools SQL

## Overview

This repository contains searches in the form of SQL queries that have 
been exported individually using Enterprise Architect (EA). This makes 
it easier to version control them and collaborate with others to further
develop the query collection.

In addition, this repository contains a set of search views that are 
based on the searches, for easier identification of certain model 
elements.

## Installation

The first option is to import the EA Modelling Tools SQL MDG Technology 
(mdg_eamt_sql.xml). Import makes the model searches available in the 
search category "EA Modelling Tools SQL" in the Find in Project window 
and makes the search views available under the root-node "EA Modelling 
Tools  SQL Views" in the Model Views window. With this option, the model
 searches and model views are not editable. Therefore, import the MDG if
 you only want to use the searches and views. See the EA User Guide for 
how to 
[import an MDG Technology](https://sparxsystems.com/eahelp/importmdgtechnologies.html).

The second option is to import the searches (ea_search.xml) and the 
views (ea_modelviews.xml) so they appear in search category "My 
Searches" in the Find in Project window and under "EA Modelling Tools 
SQL Views" in the Model Views window, respectively. With this option, 
the searches and views are editable. This option is applicable if you 
want to modify  the searches and views and update them in this 
repository. See the EA User Guide for how to import
[model searches](https://sparxsystems.com/eahelp/search_view.html)
and how to import [model views](https://sparxsystems.com/eahelp/model_views.html).

## Usage

### Model searches

Access the search functionality by pressing <kbd>Ctrl</kbd> + 
<kbd>F</kbd>.

Sparx Systems has published a video about model searches, watch it
[here](https://sparxsystems.com/resources/show-video.html?video=gettingstarted-modelsearchbasics).

The model searches in this repository are searches that are not based on
 the Query Builder, but on the SQL Editor.
 
The queries in this repository have been tested with .qea file 
repositories, which are based on [SQLite](https://sqlite.org/).

See also the section on
[Model Search](https://sparxsystems.com/eahelp/search_view.html)
in the EA User Guide.

### Search views

Access the model view functionality by going to
Start > All Windows > Design > Explore > Focus > Model Views.

The model views in this repository are search views that are based 
on the model searches in this repository. They are organized in view 
folders. Each view folder organizes a set of model searches that return 
elements that are not in accordance with a certain set of modelling 
rules.

⚠ A search view can only show model elements that are also available in 
the browser window. This means that connectors and association ends will
 not be shown in search views even though they are present in the 
results of the model search. Therefore, often, sets of related search 
views are present:

1. One search view based on the model search that finds attributes 
(shown in the search view) and associations ends (not shown in the 
search view). For example, a search view based on model search 
`properties_without_explicit_multiplicity`.
2. A second search view based on a similar search that finds association 
ends and that matches the associations ends to the classifiers they are
 a property of (`t_object.ea_guid AS CLASSGUID` instead of 
`t_connector.ea_guid AS CLASSGUID`, see below). For example, a search
view based on model search 
`classifiers_with_navigable_association_ends_without_explicit_multiplicity`.

See also the section on
[Model Views](https://sparxsystems.com/eahelp/model_views.html)
in the EA User Guide.

## Writing new queries

### Formatting

The formatting of the queries is not important when running a search 
from the "Find in Project" tab. However, the formatting is important
when the queries are supposed to be reused in, for example, the 
creation of search views in the Model Views tab or the
[creation of model documents](https://sparxsystems.com/eahelp/createadocumentobject.html).

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
[Create Search Definitions](https://sparxsystems.com/eahelp/creating_filters.html)
in the EA User Guide for more information.

### Column CLASSTYPE

The query must include the phrase `<classtype> AS CLASSTYPE` so that an 
icon can be displayed for the model element. Possible values for 
`<classtype>` are shown in the table below.

| Table | CLASSTYPE | Icon | Comment |
|---|---|---|---|
| t_package | 'Package' | ![package](http://demo.sparxpublic.com/images/element64/package.png "package") | |
| t_object | t_object.object_type | Depends on `object_type`:<br />![class](http://demo.sparxpublic.com/images/element64/class.png "class")<br />![data type](http://demo.sparxpublic.com/images/element64/datatype.png "data type")<br />![enumeration](http://demo.sparxpublic.com/images/element64/enumeration.png "enumeration")<br />…| |
| t_attribute | 'Attribute' | ![attribute](http://demo.sparxpublic.com/images/element64/attribute.png) | |
| t_connector | t_connector.connector_type | Depends on `connector_type`:<br />![association](http://demo.sparxpublic.com/images/element64/association.png "association")<br />![generalization](http://demo.sparxpublic.com/images/element64/generalization.png "generalization")<br />![aggregation](http://demo.sparxpublic.com/images/element64/aggregation.png "aggregation or composition")<br />… | Connector ends are not stand-alone objects in EA. Use `t_connector.connector_type` when the focus is on the connector itself. |
| t_connector | 'AssociationEnd' | ![association end](http://demo.sparxpublic.com/images/element64/associationend.png "association end") | Connector ends are not stand-alone objects in EA. Use `AssociationEnd` when the connector is an association (including aggregations and compositions) and when the focus is on the association end. |
| t_diagram | t_diagram.diagram_type | ![diagram](http://demo.sparxpublic.com/images/element64/diagram.png "diagram") | |

`CLASSTYPE` is not shown as a column in the results.

EA does not distinguish between attributes and enumeration literals with
 regard to the symbol.

See the section
[Create Search Definitions](https://sparxsystems.com/eahelp/creating_filters.html)
in the EA User Guide for more information.

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
[Create Search Definitions](https://sparxsystems.com/eahelp/creating_filters.html)
in the EA User Guide for more information.

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
[Create Search Definitions](https://sparxsystems.com/eahelp/creating_filters.html)
in the EA User Guide for more information.

### Queries with common table expressions

EA expects a query to start with `SELECT`. Nest a query using a
[common table expression](https://en.wikipedia.org/wiki/Hierarchical_and_recursive_queries_in_SQL#Common_table_expression)
in a simple query to get around this:

```sql
SELECT
	*
FROM
	(
WITH RECURSIVE self_and_ancestors AS (
	SELECT
		*
	FROM
		t_package
	WHERE
		t_package.package_id = #Package#
UNION ALL
	SELECT
		p.*
	FROM
		t_package AS p,
		self_and_ancestors AS s
	WHERE
		p.package_id = s.parent_id
)
	SELECT
		name
	FROM
		self_and_ancestors);;
```

### Exporting queries

The queries are exported using the built-in functionality. Each query 
has to be saved in a separate file, to make it easier to track changes.

## Creating new search views

The search views are maintained in EA, in Model View root node "EA 
Modelling Tools SQL".

Make sure that the GUID of Model View root node "EA Modelling Tools SQL"
 is the same as the GUID in this repository before exporting the model 
views. EA changes the GUID of that node upon import (the other GUIDs are
 kept). The GUIDs can be updated with a dedicated SQLite tool using the 
following queries. Close your EA project before executing the queries.

```sql
SELECT xrefid FROM t_xrefsystem WHERE name = 'EA Modelling Tools SQL';
UPDATE t_xrefsystem SET xrefid = '{B9DDF7FF-6B27-425b-B741-A8C69E89C6DB}' WHERE xrefid = 'replace_with_xref_id_from_first_query';
UPDATE t_xrefsystem SET supplier = '{B9DDF7FF-6B27-425b-B741-A8C69E89C6DB}' WHERE supplier = 'replace_with_xref_id_from_first_query';
```

The search views are exported using the
[built-in functionality](https://sparxsystems.com/eahelp/model_views.html).
The search views are exported together in one file.

File modelviews.xml has to be formatted before it is committed, to make 
it easier to see changes between commits. Use e.g. the Pretty Print 
option from the XML Tools plugin in Notepad++. The file in the 
repository is formatted with a tab size of 4 and spaces instead of tabs.

If the search views need to be reorganised (e.g. moved to a different
category):

1. Export the latest version you have in EA
2. Format the resulting XML file (see above)
3. Reorganise the search views in the XML file
4. Delete the EA Modelling Tools SQL model views from EA
5. Import the search views in the reorganised XML file

The GUIDs of the root node (`<RootView>`), views folders (`<Category>`) 
and search views (`<Search>`) are kept by following the procedures 
above. Keeping the GUIDs improves the traceability of changes.

## Building

It is a prerequisite that [Saxon](https://www.saxonica.com) is installed
 and that the environment variable `SAXON_CP` points to the location of 
the main Saxon jar file.

Run the [Powershell](https://learn.microsoft.com/en-us/powershell/) 
scripts from directory `ea-modelling-tools-sql`, not from directory 
`build`.

```PowerShell
.\build\build.ps1 -mdgVersion:a.b.c
```

The scripts are combined into four files:

1. an MDG Technology (mdg_eamt_sql.xml);
2. a file containing the searches, following the same structure as in 
searches exported from EA and as in C:\Users\<username>\AppData\Roaming\Sparx Systems\EA\Search Data\EA_Search.xml
(ea_search.xml);
3. a file containing the search views (ea_modelviews.xml), a simple copy of the search views file in the source code;
4. an HTML file listing all the searches and their comments 
(ea_search_doc.xhtml).
