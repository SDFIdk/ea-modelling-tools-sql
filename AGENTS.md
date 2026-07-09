# AGENTS.md

## Purpose

This repository contains SQL queries used as model searches in Sparx Enterprise Architect (EA). The queries run against `.qea` file repositories, which are based on SQLite. When writing or modifying queries, follow the rules below. They are ordered to match the structure of a SQL query.

## Database schema
 
Before writing or modifying a query, consult the database schema documented in [docs/database-schema.md](docs/database-schema.md) to verify that every table and column you intend to use actually exists. Do not assume column names from conventions or similar projects - look them up.

## `#xxx#` macros

`#xxx# macros` can be used as string replacers. These macros are all case-sensitive. This is EA-specific functionality.

The most important macros are:

- `#Branch#`: Gets the ID of each child Package under one or more parent Packages, working recursively down to the lowest level of sub-Package.
  - `IN #Branch#`: Gets the ID of each child Package of the parent Package selected by the user.
  - `IN #Branch=<GUID>#` or `#Branch=<ID>#`: Gets the ID of each child Package of the parent Package specified by the GUID or ID.
  - `IN #Branch=<ID>,<ID>,<ID>#`: Gets the ID of each child Package under each parent Package specified by its ID.
- `#Concat <value1>, <value2>, ...#`: Provides a method of concatenating two or more SQL terms into one string, independent of the database type.
- `#CurrentElementGUID#`: Gets the ea_guid for the currently-selected element.
- `#CurrentElementID#`: Gets the Object_ID for the currently selected element.
- `#Package#`: Gets the Package_ID for the currently-selected Package.
- `#Substring <field>, <start>#`: Returns the remainder of the field beginning at the 'start' character (1-based)
- `#Substring <field>, <start>, <count>#`: Returns the "count" number of characters of the field starting at character "start" (1-based).

## Search term

In addition to macros, `<Search Term>` can be used in queries. It gets 
the value on which to search, from the text entered in the "Search Term"
 field in the Find in Project view. It therefore functions when an 
active search is being run and values are being placed in that field. It
 must appear inside a string, and is required to be in quotes if the 
value it is being compared with is of type string.

## Output format

Produce only the raw SQL query. Do not wrap it in an XML element such as `/RootSearch/Search/SrchOn/RootTable`.

Add a trailing comment line immediately after the closing semicolon to describe what the query returns:

```
#DB=COMMENT# <description> #DB=COMMENT#
```

Add regular SQL comments (`-- `) only to describe things that are not obvious from the query:
  - "Obvious" is from the perspective of someone else reading the query for the first time but that has access to the documentation of the tables and columns.
  - Help readers to understand what the query is doing, not how it does it.

## WITH CLAUSE

EA expects a query to start with `SELECT`. Nest a query using a
common table expression (CTE) in a simple query to get around this:

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
		self_and_ancestors);
```

## SELECT clause

Add the special EA column aliases `CLASSGUID` and `CLASSTYPE`, unless explicitly requested otherwise. In queries for connectors and diagrams, add also `CLASSTABLE`, unless explicitly requested otherwise. Possible values for `CLASSTABLE` are:

| Table | CLASSTYPE | Comment |
|---|---|---|
| t_package | 'Package' |  |
| t_object | t_object.object_type |  |
| t_attribute | 'Attribute' |  |
| t_connector | t_connector.connector_type | Connector ends are not stand-alone objects in EA. Use `t_connector.connector_type` when the focus is on the connector itself. |
| t_connector | 'AssociationEnd' | Connector ends are not stand-alone objects in EA. Use `AssociationEnd` when the connector is an association (including aggregations and compositions) and when the focus is on the association end. |
| t_diagram | t_diagram.diagram_type |  |


Write SQL keywords (`SELECT`, `FROM`, `WHERE`, `AND`, `IN`, `INNER JOIN`, `LEFT JOIN`, `ON`, `AS`, `UNION`, `ORDER BY`, `DISTINCT`, `NULL`, `CAST`, `NOT`, etc.) in UPPER CASE.

Write table names and column names in lower case, regardless of how they appear in the EA database schema.

Use the `AS` keyword for column aliases.

Write the special EA column aliases `CLASSGUID`, `CLASSTYPE`, and `CLASSTABLE` in UPPER CASE. Write all other column aliases in lower case, unless explicitly requested otherwise.

Add a column alias when two or more returned columns from different tables share the same name (e.g. two tables both have `object_id`).

Add a column alias when a column is calculated using operators and/or functions and would otherwise get a long name or a name containing non-alphanumeric characters.

Do not add a column alias otherwise, unless explicitly requested otherwise.

For queries using `UNION`, only use column aliases in the first subquery.

## FROM and JOIN clauses

Use the standard alias for a table when that table appears exactly once in a (sub)query:

| Table | Standard alias |
|---|---|
| `t_attribute` | `a` |
| `t_attributetag` | `at` |
| `t_connector` | `c` |
| `t_diagram` | `d` |
| `t_diagramlinks` | `dl` |
| `t_diagramobjects` | `do` |
| `t_object` | `o` |
| `t_objectproperties` | `op` |
| `t_package` | `p` |
| `t_taggedvalue` | `tv` |
| `t_xref` | `x` |

When a table appears more than once in the same (sub)query, use a descriptive alias instead (e.g. `t_object o_start` and `t_object o_end`).

Write table aliases in lower case. Do not use the `AS` keyword for table aliases.

Write `INNER JOIN`, not bare `JOIN`.

Write `LEFT JOIN`, not `LEFT OUTER JOIN`.

Do not use `RIGHT JOIN`. Reorder the tables and use `LEFT JOIN` instead.

## WHERE clause

Limit results to the selected package and its subpackages using the `#Branch#` macro: `package_id IN (#Branch#)`, unless explicitly requested otherwise.

## Expressions
 
Use `CASE WHEN x THEN y ELSE z END` instead of `iif(x, y, z)`.
 
Before concatenating values, check whether each column can contain NULL by consulting the database schema. If it can, wrap it in a `CASE` expression to avoid the concatenation silently producing NULL when any operand is NULL.

Only use built-in functions. E.g., do not use the `REGEXP` operator, as it is a special syntax for the `regexp()` user function and no `regexp()` user function is defined by default.

When incrementing a recursion depth/level counter in a recursive common table expression (CTE), write `level * 2` instead of `level + 1`. This works around a bug in EA where EA performs string concatenation instead of numeric addition (see [Sparx forum thread](https://sparxsystems.com/forums/smf/index.php/topic,48040.0.html)). Multiplication is unaffected and still produces increasing values.

## Examples

### Example 1

```sql
SELECT
	o.ea_guid AS CLASSGUID,       -- UPPER CASE: special EA alias
	o.object_type AS CLASSTYPE,   -- UPPER CASE: special EA alias
	o.name,                       -- no alias needed
	op.property,
	op.value
FROM
	t_object o                    -- standard alias, no AS
LEFT JOIN t_objectproperties op ON  -- LEFT JOIN, not LEFT OUTER JOIN
	o.object_id = op.object_id
WHERE
	o.package_id IN (#Branch#)    -- scope to selected package via #Branch# macro
	AND o.object_type IN ('Class')
	AND op.value != '<memo>';
#DB=COMMENT# Finds all classes and their non-memo tagged values. #DB=COMMENT#
```

### Example 2

```sql
SELECT
	c.ea_guid AS CLASSGUID,             -- UPPER CASE: special EA alias
	c.connector_type AS CLASSTYPE,      -- UPPER CASE: special EA alias
    't_connector' AS CLASSTABLE,        -- UPPER CASE: special EA alias
	o_start.name AS source_class,       -- alias: name collision across tables
	(CASE WHEN c.sourcerole IS NULL THEN '' ELSE c.sourcerole END
		|| CASE c.direction
			WHEN 'Destination -> Source' THEN ' <-'
			WHEN 'Source -> Destination' THEN ' ->'
			WHEN 'Bi-Directional' THEN ' <->'
			ELSE ' --'
		END
		|| ' ' || CASE WHEN c.destrole IS NULL THEN '' ELSE c.destrole END) AS combined_role,  -- alias: calculated; NULL-guarded: sourcerole and destrole are nullable
	o_end.name AS destination_class    -- alias: name collision across tables
FROM
	t_connector c                       -- standard alias
INNER JOIN t_object o_start ON          -- descriptive alias: t_object appears twice
	c.start_object_id = o_start.object_id
INNER JOIN t_object o_end ON            -- descriptive alias: t_object appears twice
	c.end_object_id = o_end.object_id
WHERE
	o_start.package_id IN (#Branch#)
	AND c.connector_type IN ('Association', 'Aggregation');
#DB=COMMENT# Finds all associations in the selected package with source/destination class names and combined role label. #DB=COMMENT#
```