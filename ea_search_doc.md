# EA Modelling Tools SQL

## `all_attributes_classifier`

 Find the owned and inherited attributes of the classifier selected in the Project Browser. Association ends are not taken into account. Note: the query contains "level * 2" instead of the usual "level + 1". This is because there is a bug in EA that causes numeric addition not to work, see also https://sparxsystems.com/forums/smf/index.php/topic,48040.0.html. 

```sql
SELECT
	*
FROM
	(
WITH self_and_ancestor(object_id,
	name,
	level) AS (
	SELECT
		o.object_id,
		o.name,
		1
	FROM
		t_object o
	WHERE
		o.object_id = #CurrentElementID#
UNION ALL
	SELECT
		o_parent.object_id,
		o_parent.name,
		s.level * 2
	FROM
		(self_and_ancestor s
	INNER JOIN t_connector c ON
		(s.object_id = c.start_object_id
			AND c.connector_type = 'Generalization'))
	INNER JOIN t_object o_parent ON
		c.end_object_id = o_parent.object_id
),
	attributes_self_and_ancestor(CLASSGUID,
	CLASSTYPE,
	property_name,
	defining_classifier_object_id,
	defining_classifier_name,
	level) AS (
	SELECT
		a.ea_guid,
		'Attribute',
		a.name,
		o.object_id,
		o.name,
		o.level
	FROM
		t_attribute a
	INNER JOIN
	self_and_ancestor o
ON
		a.object_id = o.object_id
	)
	SELECT
		CLASSGUID,
		CLASSTYPE,
		property_name,
		defining_classifier_name
	FROM
		attributes_self_and_ancestor
	ORDER BY
		LEVEL DESC
);

```

## `associations`

 Find all associations in the selected package and its subpackages. 

```sql
SELECT
	c.ea_guid AS CLASSGUID,
	c.connector_type AS CLASSTYPE,
	't_connector' AS CLASSTABLE,
	c.name,
	c.direction,
	o_src.name as source_name,
	c.sourcerole,
	c.sourcecard,
	c.sourcestereotype,
	o_target.name as target_name,
	c.destrole,
	c.destcard,
	c.deststereotype
FROM
	(t_connector c
INNER JOIN t_object o_src ON
	c.start_object_id = o_src.object_id)
INNER JOIN t_object o_target ON
	c.end_object_id = o_target.object_id
WHERE
	((o_src.package_id IN (#Branch#)
		AND o_target.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_src.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_target.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
ORDER BY
	c.name;

```

## `associations_unspecified_direction`

 Find the associations that have an unspecified direction. 

```sql
SELECT
	c.ea_guid AS CLASSGUID,
	c.connector_type AS CLASSTYPE,
	't_connector' AS CLASSTABLE,
	c.name,
	c.direction,
	o_src.name as source_name,
	c.sourcerole,
	o_target.name as target_name,
	c.destrole
FROM
	(t_connector c
INNER JOIN t_object o_src ON
	c.start_object_id = o_src.object_id)
INNER JOIN t_object o_target ON
	c.end_object_id = o_target.object_id
WHERE
	((o_src.package_id IN (#Branch#)
		AND o_target.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_src.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_target.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.Direction = 'Unspecified'
ORDER BY
	c.name;

```

## `attributes_of_enumerations`

 Find the attributes that belong to enumerations. Typically, enumerations only have enumeration literals, not attributes. In EA, attributes and enumerations are stored in table t_attribute. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS enumeration_name,
	a.name AS attribute_name,
	a.styleex
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type = 'Enumeration'
	AND a.styleex NOT LIKE '%IsLiteral=1%';

```

## `attributes_size_precision_scale`

 Finds all the attributes, including their values for tags size, precision and scale, that have one of the following as type: CharacterString, Decimal, Integer, Real, Measure, Area, Length, DirectPosition. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'size') AS size,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'precision') AS precision,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'scale') AS scale
FROM
		((t_attribute a
INNER JOIN t_object o ON
		o.object_id = a.object_id)
INNER JOIN t_package p ON
		p.package_id = o.package_id)
WHERE
		o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	AND a.styleex NOT LIKE '%IsLiteral=1%'
	AND a.type in ('CharacterString', 'Decimal', 'Real', 'Integer', 'Measure', 'Area', 'Length', 'DirectPosition');

```

## `attributes_size_precision_scale_export`

 Finds all the attributes, including their values for tags size, precision and scale, that have one of the following as type: CharacterString, Decimal, Integer, Real, Measure, Area, Length, DirectPosition. The output of this query is the starting point for a CSV file to import with script import-data-model-custom-tags (EA Modelling Tools JavaScript): (1) use the "Copy Selected to Clipboard" functionality (see https://sparxsystems.com/eahelp/model_search_context_menu.html), (2) paste in LibreOffice Calc (use semicolon as separator, check "Trim spaces", keep the proposed character set, UTF-16), (3) modify the tagged values as needed and (4) save as a CSV file (use UTF-8 as character set, comma (,) as field delimiter and quotation mark (") as string delimiter). 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	a.ea_guid AS GUID,
	a.Name AS "UML-NAVN",
	o.Name AS NAMESPACE,
	'Attribute' AS CLASSTYPE,
	CASE
		WHEN a.styleex LIKE '%IsLiteral=1%' THEN 'ENUMERATION_LITERAL'
		ELSE 'ATTRIBUTE'
	END AS "TYPE",
	NULL AS CLASSTABLE,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'size') AS size,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'precision') AS precision,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'scale') AS scale
FROM
		((t_attribute a
INNER JOIN t_object o ON
		o.object_id = a.object_id)
INNER JOIN t_package p ON
		p.package_id = o.package_id)
WHERE
		o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	AND a.styleex NOT LIKE '%IsLiteral=1%'
	AND a.type in ('CharacterString', 'Decimal', 'Real', 'Integer', 'Measure', 'Area', 'Length', 'DirectPosition');

```

## `attributes_with_conflicting_type`

 Find the attributes that have a conflicting type, where the name of the attribute type is not equal to the name of the classifier that is specified as the type. This can for example happen when first a classifier was chosen as type in the dropdown, and then <none> was chosen as type in the drop-down. To resolve this, change the type to a data type defined by the language of the element (in the dropdown) and then change again to <none>. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	a.classifier AS type_id
FROM
	(((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id))
INNER JOIN t_object o2 ON
	o2.object_id = a.classifier
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Interface')
	AND (a.classifier IS NOT NULL
		AND a.type != o2.name)
ORDER BY
	p.name,
	o.name;

```

## `attributes_with_name_like`

 Finds all the attributes with a name like the specified search term. Specify a search term using the syntax for the LIKE operator as defined by the underlying database system. E.g. for SQLite: % matches any sequence of zero or more characters in the string, _ matches any single character in the string. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	a.classifier AS type_id
FROM
	(t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id
WHERE
	o.package_id IN (#Branch#)
	AND a.name LIKE '<Search Term>'
ORDER BY
	a.name;

```

## `attributes_with_spatial_type_19107_ed1`

 Finds all the attributes that have a type defined in model ISO 19107 Edition 1. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	a.classifier AS type_id
FROM
	t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id
INNER JOIN t_package p ON
	p.package_id = o.package_id
INNER JOIN t_object t ON
	a.classifier = t.object_id
WHERE
	o.package_id IN (#Branch#)
	AND t.package_id IN (#Branch={BBEF980E-D59E-469d-9164-7A94E1F503C7}#)
ORDER BY
	a.type;

```

## `attributes_with_type_like`

 Specify a search term using the syntax for the LIKE operator as defined by the underlying database system. E.g. for SQLite: % matches any sequence of zero or more characters in the string, _ matches any single character in the string. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	a.classifier AS type_id
FROM
	(t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id
WHERE
	o.package_id IN (#Branch#)
	AND a.type LIKE '<Search Term>'
ORDER BY
	a.type;

```

## `attributes_with_type_without_classifier`

 Find the attributes that have a type specified that is not linked to an element (classifier) in the model. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	a.classifier AS type_id
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Interface')
	AND (a.classifier IS NULL
		OR a.classifier = 0)
	AND a.type IS NOT NULL
ORDER BY
	p.name,
	o.name;

```

## `attributes_without_type`

 Find the attributes that have no type specified (<none> was chosen as type in the drop-down). 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	a.classifier AS type_id
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Interface')
	AND a.classifier = 0
	AND a.type IS NULL
ORDER BY
	p.name,
	o.name;

```

## `classes_without_context_diagram`

 Find the classes that do not have a context diagram. A context diagram must be a class diagram and it must have a name consisting of (1) the term specified as search term (e.g. "Context diagram" or "Kontekstdiagram") (2) a space and (3) the name of the class. This query is intended to be used in a model view, where the search term is fixed and valid only in a given language. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	o.name
FROM
	t_object o
WHERE
	o.package_id IN (#Branch#)
	AND object_type = 'Class'
	AND NOT EXISTS
(
	SELECT
		*
	FROM
		t_diagramobjects do
	INNER JOIN t_diagram d ON
		do.diagram_id = d.diagram_id
	WHERE
		d.diagram_type = 'Logical'
		AND d.name = #Concat '<Search Term> ', o.name#);

```

## `classifier_and_ancestors`

 Find (1) the classifier selected in the Project Browser and (2) the ancestors of that classifier. 

```sql
SELECT
	CLASSGUID,
	CLASSTYPE,
	name
FROM
	(
WITH self_and_ancestor(CLASSGUID,
	CLASSTYPE,
	object_id,
	name) AS (
	SELECT
		o.ea_guid,
		o.object_type,
		o.object_id,
		o.name
	FROM
		t_object o
	WHERE
		o.ea_guid = #CurrentElementGUID#
UNION ALL
	SELECT
		o_parent.ea_guid,
		o_parent.object_type,
		o_parent.object_id,
		o_parent.name
	FROM
		(self_and_ancestor s
	INNER JOIN t_connector c ON
		(s.object_id = c.start_object_id
			AND c.connector_type = 'Generalization'))
	INNER JOIN t_object o_parent ON
		c.end_object_id = o_parent.object_id
)
	SELECT
		*
	FROM
		self_and_ancestor
);

```

## `classifiers_with_association_ends_with_invalid_names_internal`

 Finds the classifiers for which an opposite association end has a name having characters that are invalid according to the internal rules of the agency. Model views cannot show connectors or connector ends, this query can be used in a model view search folder. See also query model_elements_invalid_names_internal. 

```sql
SELECT
	*
FROM
	(
	SELECT
		o_start.ea_guid AS CLASSGUID,
		o_start.object_type AS CLASSTYPE,
		o_start.name AS classifier_name,
		c.destrole AS property_name,
		o_end.name AS type,
		c.name AS association_name
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
UNION ALL
	SELECT
		o_end.ea_guid,
		o_end.object_type,
		o_end.name,
		c.sourcerole,
		o_start.name,
		c.name
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong')))
WHERE
	(property_name GLOB '*[^a-zA-ZæøåéÆØÅÉ0-9]*'
		OR property_name NOT GLOB '[a-zA-ZæøåéÆØÅÉ]*')
ORDER BY
	classifier_name,
	property_name;

```

## `classifiers_with_association_ends_with_notes`

 Finds the classifiers for which an opposite association end has non-null notes. Model views cannot show connectors or connector ends, this query can be used in a model view search folder.

```sql
SELECT
	*
FROM
	(
	SELECT
		o_start.ea_guid AS CLASSGUID,
		o_start.object_type AS CLASSTYPE,
		o_start.name AS classifier_name,
		c.destrole AS property_name,
		c.destrolenote AS notes
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
UNION ALL
	SELECT
		o_end.ea_guid,
		o_end.object_type,
		o_end.name,
		c.sourcerole,
		c.sourcerolenote
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
	)
WHERE
	notes IS NOT NULL
ORDER BY
	classifier_name,
	property_name;

```

## `classifiers_with_association_ends_with_stereotype_not_from_profile`

 Finds the classifiers for which an opposite association end has a stereotype not from a UML profile. Model views cannot show connectors or connector ends, this query can be used in a model view search folder. See also query stereotypes_not_from_profile 

```sql
SELECT
	*
FROM
	(
	SELECT
		o_start.ea_guid AS CLASSGUID,
		o_start.object_type AS CLASSTYPE,
		p_start.name AS package_name,
		o_start.name AS classifier_name,
		c.destrole AS property_name,
		c.deststereotype AS primary_unqualified_stereotype,
		x.description AS stereotypes
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorDestEnd property'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
UNION ALL
	SELECT
		o_end.ea_guid,
		o_end.object_type,
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcestereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorSrcEnd property'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
)
WHERE
	(stereotypes LIKE '%GUID%'
		OR (stereotypes NOT LIKE '%GUID%'
			AND stereotypes NOT LIKE '%FQNAME%'))
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `classifiers_with_associations_or_association_ends_with_duplicate_tags`

 Find the classifiers with association ends and relationships that have more than one tagged value with the same name. Model views cannot show connectors or connector ends, this query can be used in a model view search folder. See also query model_elements_duplicate_tags. 

```sql
SELECT
	o_start.ea_guid AS CLASSGUID,
	o_start.object_type AS CLASSTYPE,
	o_start.name AS classifier_name,
	c.name AS element_name,
	'association' AS element_type,
	ct.property AS tag_name
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_connectortag ct ON
	ct.elementid = c.connector_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
GROUP BY
	c.ea_guid,
	c.connector_type,
	c.name,
	ct.property
HAVING
	count(ct.property) > 1
UNION ALL
SELECT
	o_end.ea_guid,
	o_end.object_type,
	o_end.name,
	c.sourcerole,
	'source association end',
	tv.tagvalue
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
GROUP BY
	c.ea_guid,
	c.connector_type,
	c.sourcerole,
	tv.tagvalue
HAVING
	count(tv.tagvalue) > 1
UNION ALL
SELECT
	o_start.ea_guid,
	o_start.object_type,
	o_start.name,
	c.destrole,
	'target association end',
	tv.tagvalue
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
GROUP BY
	c.ea_guid,
	c.connector_type,
	c.destrole,
	tv.tagvalue
HAVING
	count(tv.tagvalue) > 1;

```

## `classifiers_with_associations_with_unspecified_direction`

 Find the classifiers with associations that have an unspecified direction. Model views cannot show connectors or connector ends, this query can be used in a model view search folder. See also query associations_unspecified_direction. 

```sql
SELECT
	o_start.ea_guid AS CLASSGUID,
	o_start.object_type AS CLASSTYPE,
	c.name AS association_name,
	c.direction,
	o_start.name as source_name,
	c.sourcerole,
	o_end.name as target_name,
	c.destrole
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.Direction = 'Unspecified'
ORDER BY
	c.name;

```

## `classifiers_with_duplicate_names`

 Find the classifiers that have the same name as another classifier in the given package and its subpackages. This interpretation is stricter than the UML 2.5.1 specification, where a package is a namespace, and its subpackages are other namespaces. This query also finds the classifiers that have the same name but are of a different kind. This interpretation is stricter than the UML 2.5.1 specification, that permits named elements to have the same name if they are of a different kind. See operation isDistinguishableFrom() in clause 7.8.9.7, operation membersAreDistinguishable() in clause 7.8.10.8 and constraint members_distinguisable in clause 7.8.10.7. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	o.name,
	o.object_type,
	o.stereotype
FROM
	t_object o
WHERE
	o.package_id IN (#Branch#)
	AND object_type IN ('Class', 'Enumeration', 'Interface', 'DataType')
	AND EXISTS
(
	SELECT
		*
	FROM
		t_object o2
	WHERE
		o2.package_id IN (#Branch#)
			AND o2.name = o.name
			AND o2.ea_guid <> o.ea_guid);

```

## `classifiers_with_navigable_association_ends_without_explicit_multiplicity`

 Find classifiers that have properties in the form of navigable association ends that don't have a multiplicity specified explicitly. If it is not specified, it is assumed to be 1, according to the UML specification. However, having a explicitly specified multiplicity is preferable. Model views cannot show connectors or connector ends, this query can be used in a model view search folder. 

```sql
SELECT
	o_start.ea_guid AS CLASSGUID,
	o_start.object_type AS CLASSTYPE,
	o_start.name AS classifier_name,
	c.destrole AS property_name,
	o_end.name AS type,
	c.name AS association_name
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
	AND c.destcard IS NULL
UNION ALL
SELECT
	o_end.ea_guid,
	o_end.object_type,
	o_end.name,
	c.sourcerole,
	o_start.name,
	c.name
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
	AND c.sourcecard IS NULL;

```

## `constraints`

 For more information about constraints in t_objectconstraint, see https://sparxsystems.com/eahelp/constraints.html. For more information about constraints in t_object, see https://sparxsystems.com/eahelp/element_constraint.html. "constraint" is a reserved word, therefore the square brackets are needed for columns with name "Constraint". Not (yet?) implemented are the following: (1) take into account the tables t_attributeconstraints, t_connectorconstraint and t_roleconstraint; (2) check connectors of type NoteLink and check t_object.PDATA4 to find the model elements that are constrained by the constraints in t_object. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	o.name AS constrained_element_name,
	oc.[Constraint] AS constraint_name,
	oc.notes AS constraint_text
FROM
	t_objectconstraint oc
INNER JOIN t_object o ON
	o.object_id = oc.object_id
WHERE
	o.package_id IN (#Branch#)
UNION ALL
SELECT
	o.ea_guid,
	o.object_type,
	'(see diagram)',
	o.name,
	o.note
FROM
	t_object o
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type = 'Constraint';

```

## `context_diagrams_missing_model_elements`

 Finds the context diagrams for which any of the following is true: (1) the context diagram name does not indicate a classifier that actually exists in the model; (2) the context diagram does not actually contain the classifier indicated by the diagram name; (3) the context diagram does not contain all the classifiers that (a) are the type of one of the attributes of the central classifier and (b) are defined in the same model as the central classifier; (4) the context diagram does not contain all the classifiers that are the type of a navigable association end of the central classifier. Example for 1: if a context diagram has "MyObject" as central classifier, and if "MyObject" has an attribute with type "MyDataType", and if "MyDataType" is defined in the same model as "MyObject", then the context diagram will be returned if "MyDataType" is not present on the context diagram. This query is intended to be used in a model view, where the search term is fixed and valid only in a given language. 

```sql
SELECT
	*
FROM
	(
WITH
context_diagrams AS (
    SELECT
        d.ea_guid AS CLASSGUID,
        d.diagram_type AS CLASSTYPE,
        't_diagram' AS CLASSTABLE,
        d.diagram_id,
        d.name AS diagram_name,
        replace(d.name, '<Search Term> ', '') AS central_classifier_name,
        o.object_id AS central_classifier_id
    FROM
        t_diagram d
    LEFT JOIN t_object o ON
        d.name = #Concat '<Search Term> ', o.name#
        AND o.package_id IN (#Branch#)
    WHERE
        d.package_id IN (#Branch#)
        AND d.name LIKE '<Search Term>%'
),
attributes_with_type AS (
	SELECT
		o.object_id AS classifier_id,
		a.id AS attribute_id,
		a.name AS attribute_name,
		t.object_id AS type_id,
		t.name AS type_name,
		t.package_id AS type_package_id
	FROM
		t_object o
	INNER JOIN t_attribute a ON
		o.object_id = a.object_id
	INNER JOIN t_object t ON
		a.classifier = t.object_id
	WHERE
		o.package_id IN (#Branch#)
			AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
				AND a.styleex NOT LIKE '%IsLiteral=1%'
),
	navigable_association_ends AS (
	SELECT
		o_start.object_id AS start_classifier_id,
		o_start.name AS start_classifier_name,
		c.connector_id AS association_id,
		c.name AS association_name,
		c.destrole AS end_classifier_role,
		o_end.object_id AS end_classifier_id,
		o_end.name AS end_classifier_name
	FROM
		(t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
UNION ALL
	SELECT
		o_end.object_id,
		o_end.name,
		c.connector_id,
		c.name,
		c.sourcerole,
		o_start.object_id,
		o_start.name
	FROM
		(t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
)
	SELECT
		d.CLASSGUID,
		d.CLASSTYPE,
		d.CLASSTABLE,
		d.diagram_name,
		d.central_classifier_name AS model_element_name,
		#Concat 'No classifier with name ', d.central_classifier_name, ' found in the selected package'# AS info
	FROM
		context_diagrams d
	WHERE
		d.central_classifier_id IS NULL
UNION ALL
	SELECT
		d.CLASSGUID,
		d.CLASSTYPE,
		d.CLASSTABLE,
		d.diagram_name,
		d.central_classifier_name,
		#Concat d.central_classifier_name, ' is supposed to be the central classifier of this diagram according to the diagram''s name'#
	FROM
		context_diagrams d
	WHERE
		d.central_classifier_id IS NOT NULL AND NOT EXISTS (
		SELECT
			*
		FROM
			t_diagramobjects do
		WHERE
			do.diagram_id = d.diagram_id
			AND do.object_id = d.central_classifier_id)
UNION ALL
	SELECT
		d.CLASSGUID,
		d.CLASSTYPE,
		d.CLASSTABLE,
		d.diagram_name,
		a.type_name,
		#Concat a.type_name, ' is the type of attribute ', a.attribute_name, ' and is defined in the selected package'#
	FROM
		context_diagrams d
	INNER JOIN attributes_with_type a ON
		d.central_classifier_id = a.classifier_id
	WHERE
		a.type_package_id IN (#Branch#)
		AND NOT EXISTS (
		SELECT
			*
		FROM
			t_diagramobjects do
		WHERE
			do.diagram_id = d.diagram_id
			AND do.object_id = a.type_id)
UNION ALL
	SELECT
		d.CLASSGUID,
		d.CLASSTYPE,
		d.CLASSTABLE,
		d.diagram_name,
		n.end_classifier_name,
		#Concat end_classifier_name, ' is the type of association end ', CASE WHEN end_classifier_role IS NULL THEN '(no name)' ELSE end_classifier_role END#
	FROM
		context_diagrams d
	INNER JOIN navigable_association_ends n ON
		d.central_classifier_id = n.start_classifier_id
	WHERE
		NOT EXISTS (
		SELECT
			*
		FROM
			t_diagramobjects do
		WHERE
			do.diagram_id = d.diagram_id
			AND do.object_id = n.end_classifier_id)
UNION ALL
	SELECT
		d.CLASSGUID,
		d.CLASSTYPE,
		d.CLASSTABLE,
		d.diagram_name,
		n.association_name,
		#Concat 'The association between ', d.central_classifier_name, ' and ', n.end_classifier_name, ' is hidden '#
	FROM
		context_diagrams d
	INNER JOIN navigable_association_ends n ON
		d.central_classifier_id = n.start_classifier_id
	INNER JOIN t_diagramlinks dl ON
		n.association_id = dl.connectorid AND d.diagram_id = dl.diagramid
	WHERE
		dl.hidden = 1
)
;

```

## `context_diagrams_superfluous_model_elements`

 Finds the context diagrams for which any of the following is true: (1) the context diagram contains a data type (an enumeration is a kind of data type) that is not the type of any of the attributes of the classifiers on the diagram; (2) the context diagram contains an association that is not an outgoing association of the central classifier. This query is intended to be used in a model view, where the search term is fixed and valid only in a given language. 

```sql
SELECT
	*
FROM
	(
WITH
context_diagrams AS (
	SELECT
		d.ea_guid AS diagram_ea_guid,
		d.diagram_type AS diagram_type,
		d.diagram_id,
		d.name AS diagram_name,
		replace(d.name, '<Search Term> ', '') AS central_classifier_name,
		o.object_id AS central_classifier_id
	FROM
		t_diagram d
	LEFT JOIN t_object o ON
		d.name = #Concat '<Search Term> ', o.name#
		AND o.package_id IN (#Branch#)
	WHERE
		d.package_id IN (#Branch#)
		AND d.name LIKE '<Search Term>%'
),
	classifiers_on_context_diagrams AS (
	SELECT
		d.*,
		o.object_id AS classifier_id,
		o.object_type AS classifier_type,
		o.name AS classifier_name
	FROM 
		t_object o
	INNER JOIN t_diagramobjects do ON
		o.object_id = do.object_id
	INNER JOIN context_diagrams d ON
		do.diagram_id = d.diagram_id
	WHERE
		o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
)
,
	attributes_on_context_diagrams AS (
	SELECT
		c.*,
		a.id AS attribute_id,
		a.name AS attribute_name,
		t.object_id AS type_id,
		t.name AS type_name,
		t.package_id AS type_package_id
	FROM
		classifiers_on_context_diagrams c
	INNER JOIN t_attribute a ON
		c.classifier_id = a.object_id
	INNER JOIN t_object t ON
		a.classifier = t.object_id
	WHERE
		a.styleex NOT LIKE '%IsLiteral=1%'
),
	navigable_association_ends AS (
	SELECT
		o_start.object_id AS start_classifier_id,
		o_start.name AS start_classifier_name,
		c.connector_id AS association_id,
		c.name AS association_name,
		c.direction AS association_direction,
		c.destrole AS end_classifier_role,
		o_end.object_id AS end_classifier_id,
		o_end.name AS end_classifier_name
	FROM
		(t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
UNION ALL
	SELECT
		o_end.object_id,
		o_end.name,
		c.connector_id,
		c.name,
		c.direction,
		c.sourcerole,
		o_start.object_id,
		o_start.name
	FROM
		(t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
),
	visible_navigable_association_ends_on_context_diagrams AS (
	SELECT
		c.*,
		n.*
	FROM
		context_diagrams c
		INNER JOIN t_diagramlinks dl ON
			c.diagram_id = dl.diagramid
		INNER JOIN navigable_association_ends n ON
			dl.connectorid = n.association_id
	WHERE
		dl.hidden = 0
)
	SELECT
		c.diagram_ea_guid AS CLASSGUID,
		c.diagram_type AS CLASSTYPE,
		't_diagram' AS CLASSTABLE,
		c.diagram_name,
		c.classifier_name AS model_element_name,
		#Concat c.classifier_name, ' is not a type of any of the attributes on the diagram'# AS info
	FROM
		classifiers_on_context_diagrams c
	WHERE
		c.classifier_id <> c.central_classifier_id
		AND c.classifier_type IN ('DataType', 'Enumeration')
		AND c.classifier_id NOT IN (
		SELECT
			a.type_id
		FROM
			attributes_on_context_diagrams a
		WHERE
			a.diagram_id = c.diagram_id)
UNION ALL
	SELECT
		v.diagram_ea_guid AS CLASSGUID,
		v.diagram_type AS CLASSTYPE,
		't_diagram' AS CLASSTABLE,
		v.diagram_name,
		v.association_name AS model_element_name,
		#Concat 'The association from ', v.start_classifier_name, ' to ', v.end_classifier_name, ' is not an outgoing assocation of the central classifier ', v.central_classifier_name#
	FROM
		visible_navigable_association_ends_on_context_diagrams v
	WHERE
		v.start_classifier_id <> v.central_classifier_id
		AND v.association_direction <> 'Bi-Directional'
);

```

## `data_model_vocabulary_da`

 The output of this query is the starting point for a CSV file to either include in a data vocabulary or use as a standalone data vocabulary written in AsciiDoc: (1) use the "Copy Selected to Clipboard" functionality (see https://sparxsystems.com/eahelp/model_search_context_menu.html), (2) paste in LibreOffice Calc (use semicolon as separator, check "Trim spaces", keep the proposed character set, UTF-16), (3) remove any redundant rows (4) save as a CSV file (use UTF-8 as character set, comma (,) as field delimiter and quotation mark (") as string delimiter). 

```sql
SELECT
	*
FROM
	(
WITH 
object_tagged_values(object_id, tagname, tagvalue) AS (
	SELECT
		op.object_id,
		op.property,
		op.value
	FROM
		t_objectproperties op
	WHERE
		op.value != '<memo>'
UNION ALL
	SELECT
		op.object_id,
		op.property,
		op.notes
	FROM
		t_objectproperties op
	WHERE
		op.value = '<memo>'),
	attribute_tagged_values(attribute_id, tagname, tagvalue) AS (
	SELECT
		at.elementid,
		at.property,
		at.value
	FROM
		t_attributetag at
	WHERE
		at.value != '<memo>'
UNION ALL
	SELECT
		at.elementid,
		at.property,
		at.notes
	FROM
		t_attributetag at
	WHERE
		at.value = '<memo>'),
	associationend_tagged_values(connector_guid, baseclass, tagname, tagvalue) AS (
	SELECT
		tv.elementid,
		tv.baseclass,
		tv.tagvalue,
		CASE
			WHEN instr(tv.notes, '$ea_notes=') = 0
	THEN tv.notes
			ELSE substr(tv.notes, 1, instr(tv.notes, '$ea_notes=') - 1)
		END
	FROM
		t_taggedvalue tv
	WHERE
		tv.baseclass IN ('ASSOCIATION_SOURCE', 'ASSOCIATION_TARGET')
			AND instr(tv.notes, '<memo>$ea_notes=') = 0
	UNION ALL
		SELECT
			tv.elementid,
			tv.baseclass,
			tv.tagvalue,
			substr(tv.notes, 17)
		FROM
			t_taggedvalue tv
		WHERE
			tv.baseclass IN ('ASSOCIATION_SOURCE', 'ASSOCIATION_TARGET')
				AND instr(tv.notes, '<memo>$ea_notes=') = 1),
	modellabel(visiblelabel, tooltiplabel) AS (
	SELECT
		CASE
			WHEN tv1.tagvalue IS NULL
				AND tv2.tagvalue IS NULL THEN p.name
				WHEN tv1.tagvalue IS NOT NULL
				AND tv2.tagvalue IS NULL THEN tv1.tagvalue
				WHEN tv1.tagvalue IS NULL
				AND tv2.tagvalue IS NOT NULL THEN p.name || ' v' || tv2.tagvalue
				WHEN tv1.tagvalue IS NOT NULL
				AND tv2.tagvalue IS NOT NULL THEN tv1.tagvalue || ' v' || tv2.tagvalue
			END,
			CASE
				WHEN tv1.tagvalue IS NULL THEN p.name
				WHEN tv1.tagvalue IS NOT NULL THEN tv1.tagvalue
			END
		FROM
			t_object o
		INNER JOIN t_package p ON
			o.ea_guid = p.ea_guid
		LEFT JOIN object_tagged_values tv1 ON
			o.object_id = tv1.object_id
			AND tv1.tagname = 'title (da)'
		LEFT JOIN object_tagged_values tv2 ON
			o.object_id = tv2.object_id
			AND tv2.tagname = 'versionInfo'
		WHERE
			p.package_id = #Package#
			AND o.object_type = 'Package'
),
	modelinfo(text) AS (
	SELECT
		CASE
			WHEN '<Search Term>' = '' THEN m.visiblelabel
			ELSE '<Search Term>[' || m.visiblelabel || ',title=Læs mere om ' || m.tooltiplabel || ']'
		END
	FROM
		modellabel m
)
	SELECT
		DISTINCT
		m.text AS "Model",
		o.name AS "Navn i model",
		CASE
			o.object_type
			WHEN 'Class' THEN 'kl'
			WHEN 'DataType' THEN 'da'
			WHEN 'Enumeration' THEN 'en'
		END AS "Type",
		tv1.tagvalue AS "Foretrukken term",
		tv2.tagvalue AS "Definition",
		tv3.tagvalue AS "Kommentar",
		tv4.tagvalue AS "Eksempel",
		tv5.tagvalue AS "Accepterede termer",
		CASE
			WHEN tv6.tagvalue LIKE 'http%' THEN REPLACE(REPLACE(tv6.tagvalue, ' ', ''), '|||', '[§,title=Gå til den juridiske kilde] ') || '[§,title=Gå til den juridiske kilde] '
			ELSE COALESCE(tv6.tagvalue, '')
		END
		||
		CASE
			WHEN tv7.tagvalue LIKE 'http%' THEN tv7.tagvalue || '[»,title=Gå til kilden] '
			ELSE COALESCE(tv7.tagvalue, '')
		END
		||
		CASE
			WHEN tv8.tagvalue LIKE 'http%' THEN tv8.tagvalue || '[☰,title=Gå til kodelisten]'
			ELSE COALESCE(tv8.tagvalue, '')
		END AS "Info",
		tv9.tagvalue AS "Frarådede termer",
		tv10.tagvalue AS "Translitereret navn i model"
	FROM
		t_object o
	LEFT JOIN object_tagged_values tv1 ON
		o.object_id = tv1.object_id
		AND tv1.tagname = 'prefLabel (da)'
	LEFT JOIN object_tagged_values tv2 ON
		o.object_id = tv2.object_id
		AND tv2.tagname = 'definition (da)'
	LEFT JOIN object_tagged_values tv3 ON
		o.object_id = tv3.object_id
		AND tv3.tagname = 'comment (da)'
	LEFT JOIN object_tagged_values tv4 ON
		o.object_id = tv4.object_id
		AND tv4.tagname = 'example (da)'
	LEFT JOIN object_tagged_values tv5 ON
		o.object_id = tv5.object_id
		AND tv5.tagname = 'altLabel (da)'
	LEFT JOIN object_tagged_values tv6 ON
		o.object_id = tv6.object_id
		AND tv6.tagname = 'legalSource'
	LEFT JOIN object_tagged_values tv7 ON
		o.object_id = tv7.object_id
		AND tv7.tagname = 'source'
	LEFT JOIN object_tagged_values tv8 ON
		o.object_id = tv8.object_id
		AND tv8.tagname = 'vokabularium'
	LEFT JOIN object_tagged_values tv9 ON
		o.object_id = tv9.object_id
		AND tv9.tagname = 'deprecatedLabel (da)'
	LEFT JOIN object_tagged_values tv10 ON
		o.object_id = tv10.object_id
		AND tv10.tagname = 'transliteratedName',
		modelinfo m
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration')
UNION ALL
	SELECT
		DISTINCT
		m.text AS "Model",
		a.name,
		CASE
			WHEN a.styleex LIKE '%IsLiteral=1%' THEN 'ev'
			ELSE 'at'
		END,
		tv1.tagvalue,
		tv2.tagvalue,
		tv3.tagvalue,
		tv4.tagvalue,
		tv5.tagvalue,
		CASE
			WHEN tv6.tagvalue LIKE 'http%' THEN REPLACE(REPLACE(tv6.tagvalue, ' ', ''), '|||', '[§,title=Gå til den juridiske kilde] ') || '[§,title=Gå til den juridiske kilde] '
			ELSE COALESCE(tv6.tagvalue, '')
		END
		||
		CASE
			WHEN tv7.tagvalue LIKE 'http%' THEN tv7.tagvalue || '[»,title=Gå til kilden] '
			ELSE COALESCE(tv7.tagvalue, '')
		END,
		tv9.tagvalue,
		tv10.tagvalue
	FROM
		t_attribute a
	INNER JOIN
		t_object o ON
		a.object_id = o.object_id
	LEFT JOIN attribute_tagged_values tv1 ON
		a.id = tv1.attribute_id
		AND tv1.tagname = 'prefLabel (da)'
	LEFT JOIN attribute_tagged_values tv2 ON
		a.id = tv2.attribute_id
		AND tv2.tagname = 'definition (da)'
	LEFT JOIN attribute_tagged_values tv3 ON
		a.id = tv3.attribute_id
		AND tv3.tagname = 'comment (da)'
	LEFT JOIN attribute_tagged_values tv4 ON
		a.id = tv4.attribute_id
		AND tv4.tagname = 'example (da)'
	LEFT JOIN attribute_tagged_values tv5 ON
		a.id = tv5.attribute_id
		AND tv5.tagname = 'altLabel (da)'
	LEFT JOIN attribute_tagged_values tv6 ON
		a.id = tv6.attribute_id
		AND tv6.tagname = 'legalSource'
	LEFT JOIN attribute_tagged_values tv7 ON
		a.id = tv7.attribute_id
		AND tv7.tagname = 'source'
	LEFT JOIN attribute_tagged_values tv9 ON
		a.id = tv9.attribute_id
		AND tv9.tagname = 'deprecatedLabel (da)'
	LEFT JOIN attribute_tagged_values tv10 ON
		a.id = tv10.attribute_id
		AND tv10.tagname = 'transliteratedName',
		modelinfo m
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration')
UNION ALL
	SELECT
		DISTINCT
		m.text AS "Model",
		c.sourcerole,
		'ae',
		tv1.tagvalue,
		tv2.tagvalue,
		tv3.tagvalue,
		tv4.tagvalue,
		tv5.tagvalue,
		CASE
			WHEN tv6.tagvalue LIKE 'http%' THEN REPLACE(REPLACE(tv6.tagvalue, ' ', ''), '|||', '[§,title=Gå til den juridiske kilde] ') || '[§,title=Gå til den juridiske kilde] '
			ELSE COALESCE(tv6.tagvalue, '')
		END
		||
		CASE
			WHEN tv7.tagvalue LIKE 'http%' THEN tv7.tagvalue || '[»,title=Gå til kilden] '
			ELSE COALESCE(tv7.tagvalue, '')
		END,
		tv9.tagvalue,
		tv10.tagvalue
	FROM
		t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	LEFT JOIN associationend_tagged_values tv1 ON
		c.ea_guid = tv1.connector_guid
		AND tv1.tagname = 'prefLabel (da)'
		AND tv1.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv2 ON
		c.ea_guid = tv2.connector_guid
		AND tv2.tagname = 'definition (da)'
		AND tv2.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv3 ON
		c.ea_guid = tv3.connector_guid
		AND tv3.tagname = 'comment (da)'
		AND tv3.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv4 ON
		c.ea_guid = tv4.connector_guid
		AND tv4.tagname = 'example (da)'
		AND tv4.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv5 ON
		c.ea_guid = tv5.connector_guid
		AND tv5.tagname = 'altLabel (da)'
		AND tv5.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv6 ON
		c.ea_guid = tv6.connector_guid
		AND tv6.tagname = 'legalSource'
		AND tv6.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv7 ON
		c.ea_guid = tv7.connector_guid
		AND tv7.tagname = 'source'
		AND tv7.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv9 ON
		c.ea_guid = tv9.connector_guid
		AND tv9.tagname = 'deprecatedLabel (da)'
		AND tv9.baseclass = 'ASSOCIATION_SOURCE'
	LEFT JOIN associationend_tagged_values tv10 ON
		c.ea_guid = tv10.connector_guid
		AND tv10.tagname = 'transliteratedName'
		AND tv10.baseclass = 'ASSOCIATION_SOURCE',
		modelinfo m
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.sourcestereotype = 'DKEgenskab'
UNION
	SELECT
		DISTINCT
		m.text AS "Model",
		c.destrole,
		'ae',
		tv1.tagvalue,
		tv2.tagvalue,
		tv3.tagvalue,
		tv4.tagvalue,
		tv5.tagvalue,
		CASE
			WHEN tv6.tagvalue LIKE 'http%' THEN REPLACE(REPLACE(tv6.tagvalue, ' ', ''), '|||', '[§,title=Gå til den juridiske kilde] ') || '[§,title=Gå til den juridiske kilde] '
			ELSE COALESCE(tv6.tagvalue, '')
		END
		||
		CASE
			WHEN tv7.tagvalue LIKE 'http%' THEN tv7.tagvalue || '[»,title=Gå til kilden] '
			ELSE COALESCE(tv7.tagvalue, '')
		END,
		tv9.tagvalue,
		tv10.tagvalue
	FROM
		t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	LEFT JOIN associationend_tagged_values tv1 ON
		c.ea_guid = tv1.connector_guid
		AND tv1.tagname = 'prefLabel (da)'
		AND tv1.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv2 ON
		c.ea_guid = tv2.connector_guid
		AND tv2.tagname = 'definition (da)'
		AND tv2.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv3 ON
		c.ea_guid = tv3.connector_guid
		AND tv3.tagname = 'comment (da)'
		AND tv3.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv4 ON
		c.ea_guid = tv4.connector_guid
		AND tv4.tagname = 'example (da)'
		AND tv4.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv5 ON
		c.ea_guid = tv5.connector_guid
		AND tv5.tagname = 'altLabel (da)'
		AND tv5.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv6 ON
		c.ea_guid = tv6.connector_guid
		AND tv6.tagname = 'legalSource'
		AND tv6.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv7 ON
		c.ea_guid = tv7.connector_guid
		AND tv7.tagname = 'source'
		AND tv7.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv9 ON
		c.ea_guid = tv9.connector_guid
		AND tv9.tagname = 'deprecatedLabel (da)'
		AND tv9.baseclass = 'ASSOCIATION_TARGET'
	LEFT JOIN associationend_tagged_values tv10 ON
		c.ea_guid = tv10.connector_guid
		AND tv10.tagname = 'transliteratedName'
		AND tv10.baseclass = 'ASSOCIATION_TARGET',
		modelinfo m
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.deststereotype = 'DKEgenskab'
);

```

## `dependency_diagrams_missing_model_elements`

 Finds the dependency diagrams for which any of the following is true: (1) the dependency diagram does not contain the selected model itself; (2) the dependency diagram not contain all the conceptual schemas or standards that the selected model uses; (3) one or more usages modelled between the selected model and the models it uses are not visible; (4) one or more usages between the selected model and the models its uses are not modelled at all and hence missing. The conceptual schemas or standards that the selected model uses can be found with query model_dependencies. This query is intended to be used in a model view, where the search term is fixed and valid only in a given language. Note: these modelling rules require that model dependencies are modelled by means of usages (https://www.uml-diagrams.org/dependency.html#usage). 

```sql
SELECT * FROM (
	WITH RECURSIVE conceptual_schema_or_standard(package_ea_guid, package_id, name, stereotype) AS (
	SELECT 
		p.ea_guid,
		p.package_id,
		p.name,
		o.stereotype
	FROM
		t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid
	WHERE
		o.stereotype IN ('DKDomænemodel', 'AbstractSchema', 'ApplicationSchema')
		OR (
		 EXISTS (
			SELECT
				*
			FROM
				t_objectproperties op
			WHERE
				op.object_id = o.object_id
				AND lower(op.property) = 'isapplicationsschema'
				AND op.value = 'true')
		)
		OR (
			EXISTS (
				SELECT
					*
				FROM
					t_objectproperties op
				WHERE
					op.object_id = o.object_id
					AND op.property = 'name'
					AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'number'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'yearVersion'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'publicationDate'
						AND LENGTH(op.value) > 0)
		)
	), attribute_type(type_id, type_name, type_package_id) AS (
		SELECT DISTINCT
			t.object_id,
			t.name,
			t.package_id
		FROM
			t_object o
		INNER JOIN t_attribute a ON
			o.object_id = a.object_id
		INNER JOIN t_object t ON
			a.classifier = t.object_id
		WHERE
			o.package_id IN (#Branch#)
			AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
			AND instr(a.styleex, 'IsLiteral=1') = 0
			AND t.package_id <> o.package_id
	), attribute_type_package_info(type_id, type_name, package_ea_guid, package_id, package_name, parent_id, level) AS (
		SELECT
			attribute_type.type_id,
			attribute_type.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			1
		FROM
			attribute_type
		INNER JOIN t_package p
			ON attribute_type.type_package_id = p.package_id
	UNION ALL
		SELECT
			atpi.type_id,
			atpi.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			atpi.level * 2
		FROM
			attribute_type_package_info atpi
			INNER JOIN t_package p ON
				atpi.parent_id = p.package_id
		WHERE atpi.package_id NOT IN (SELECT package_id FROM conceptual_schema_or_standard)
	), attribute_type_conceptual_schema_or_standard_info(type_id, type_name, package_ea_guid, package_id, package_name) AS (
		SELECT
			type_id,
			type_name,
			package_ea_guid,
			package_id,
			package_name
		FROM
			attribute_type_package_info atpi
		WHERE level = (
				SELECT max(level)
				FROM attribute_type_package_info AS atpi2
				WHERE atpi2.type_id = atpi.type_id
			)
	), model_dependencies(package_ea_guid, package_id, package_name) AS (
	SELECT DISTINCT
		package_ea_guid,
		package_id,
		package_name
	FROM
		attribute_type_conceptual_schema_or_standard_info
	), package_dependency_diagrams(diagram_ea_guid, diagram_type, diagram_id, diagram_name, package_ea_guid, package_id, package_name) AS (
	SELECT
		d.ea_guid,
        d.diagram_type,
        d.diagram_id,
        d.name,
		p.ea_guid,
		p.package_id,
		p.name
    FROM
        t_diagram d
	INNER JOIN t_package p ON
		d.package_id = p.package_id
    WHERE
        d.package_id IN (#Branch#)
        AND d.name = #Concat '<Search Term> ', p.name#
	)
	SELECT
		pdd.diagram_ea_guid AS CLASSGUID,
		pdd.diagram_type AS CLASSTYPE,
		't_diagram' AS CLASSTABLE,
		pdd.diagram_name,
		#Concat 'Model "', pdd.package_name , '" is missing'# AS info
	FROM
		package_dependency_diagrams pdd
	WHERE NOT EXISTS (
		SELECT
			*
		FROM
			t_diagramobjects do
		INNER JOIN t_object o ON	
			do.object_id = o.object_id
		INNER JOIN t_package p ON
			o.ea_guid = p.ea_guid
		WHERE
			do.diagram_id = pdd.diagram_id
			AND p.package_id = #Package#
	)
	UNION ALL
	SELECT
		pdd.diagram_ea_guid,
		pdd.diagram_type,
		't_diagram',
		pdd.diagram_name,
		#Concat 'Model "', md.package_name , '" is missing'#
	FROM
		package_dependency_diagrams pdd,
		model_dependencies md
	WHERE NOT EXISTS (
		SELECT
			*
		FROM
			t_diagramobjects do
		INNER JOIN t_object o ON	
			do.object_id = o.object_id
		WHERE
			do.diagram_id = pdd.diagram_id
			AND o.ea_guid = md.package_ea_guid
	)
	UNION ALL
	SELECT
		pdd.diagram_ea_guid,
		pdd.diagram_type,
		't_diagram',
		pdd.diagram_name,
		#Concat 'The usage towards "', md.package_name , '" is not visible'#
	FROM
		package_dependency_diagrams pdd,
		model_dependencies md
	WHERE EXISTS (
		SELECT
			*
		FROM
			t_diagramlinks dl
		INNER JOIN t_connector c ON	
			dl.connectorid = c.connector_id
			AND c.connector_type = 'Usage'
		INNER JOIN t_object o ON	
			(c.start_object_id = o.object_id
			AND c.direction = 'Source -> Destination')
			OR (c.end_object_id = o.object_id
			AND c.direction = 'Destination -> Source')
		INNER JOIN t_package p ON
			o.ea_guid = p.ea_guid
		INNER JOIN t_object o2 ON	
			(c.end_object_id = o2.object_id
			AND c.direction = 'Source -> Destination')
			OR (c.start_object_id = o2.object_id
			AND c.direction = 'Destination -> Source')
		WHERE
			dl.diagramid = pdd.diagram_id
			AND p.package_id = #Package#
			AND o2.ea_guid = md.package_ea_guid
			AND dl.hidden = 1
	)
	UNION ALL
	SELECT
		pdd.diagram_ea_guid,
		pdd.diagram_type,
		't_diagram',
		pdd.diagram_name,
		#Concat 'No usage is present towards "', md.package_name, '"'#
	FROM
		package_dependency_diagrams pdd,
		model_dependencies md
	WHERE NOT EXISTS (
		SELECT
			*
		FROM
			t_connector c
		INNER JOIN t_object o ON	
			(c.start_object_id = o.object_id
			AND c.direction = 'Source -> Destination')
			OR (c.end_object_id = o.object_id
			AND c.direction = 'Destination -> Source')
		INNER JOIN t_package p ON
			o.ea_guid = p.ea_guid
		INNER JOIN t_object o2 ON	
			(c.end_object_id = o2.object_id
			AND c.direction = 'Source -> Destination')
			OR (c.start_object_id = o2.object_id
			AND c.direction = 'Destination -> Source')
		WHERE
			c.connector_type = 'Usage'
			AND p.package_id = #Package#
			AND o2.ea_guid = md.package_ea_guid
	)
);

```

## `dependency_diagrams_superfluous_model_elements`

 Finds the dependency diagrams for which any of the following is true: (1) the diagram contain packages that are not the selected model and not a model dependency; (2) the diagrams contains a connector from or to the selected package that is not a usage and not a note link. The conceptual schemas or standards that the selected model uses can be found with query model_dependencies. This query is intended to be used in a model view, where the search term is fixed and valid only in a given language. Note: these modelling rules require that model dependencies are modelled by means of usages (https://www.uml-diagrams.org/dependency.html#usage). 

```sql
SELECT * FROM (
	WITH RECURSIVE conceptual_schema_or_standard(package_ea_guid, package_id, name, stereotype) AS (
	SELECT 
		p.ea_guid,
		p.package_id,
		p.name,
		o.stereotype
	FROM
		t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid
	WHERE
		o.stereotype IN ('DKDomænemodel', 'AbstractSchema', 'ApplicationSchema')
		OR (
		 EXISTS (
			SELECT
				*
			FROM
				t_objectproperties op
			WHERE
				op.object_id = o.object_id
				AND lower(op.property) = 'isapplicationsschema'
				AND op.value = 'true')
		)
		OR (
			EXISTS (
				SELECT
					*
				FROM
					t_objectproperties op
				WHERE
					op.object_id = o.object_id
					AND op.property = 'name'
					AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'number'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'yearVersion'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'publicationDate'
						AND LENGTH(op.value) > 0)
		)
	), attribute_type(type_id, type_name, type_package_id) AS (
		SELECT DISTINCT
			t.object_id,
			t.name,
			t.package_id
		FROM
			t_object o
		INNER JOIN t_attribute a ON
			o.object_id = a.object_id
		INNER JOIN t_object t ON
			a.classifier = t.object_id
		WHERE
			o.package_id IN (#Branch#)
			AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
			AND instr(a.styleex, 'IsLiteral=1') = 0
			AND t.package_id <> o.package_id
	), attribute_type_package_info(type_id, type_name, package_ea_guid, package_id, package_name, parent_id, level) AS (
		SELECT
			attribute_type.type_id,
			attribute_type.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			1
		FROM
			attribute_type
		INNER JOIN t_package p
			ON attribute_type.type_package_id = p.package_id
	UNION ALL
		SELECT
			atpi.type_id,
			atpi.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			atpi.level * 2
		FROM
			attribute_type_package_info atpi
			INNER JOIN t_package p ON
				atpi.parent_id = p.package_id
		WHERE atpi.package_id NOT IN (SELECT package_id FROM conceptual_schema_or_standard)
	), attribute_type_conceptual_schema_or_standard_info(type_id, type_name, package_ea_guid, package_id, package_name) AS (
		SELECT
			type_id,
			type_name,
			package_ea_guid,
			package_id,
			package_name
		FROM
			attribute_type_package_info atpi
		WHERE level = (
				SELECT max(level)
				FROM attribute_type_package_info AS atpi2
				WHERE atpi2.type_id = atpi.type_id
			)
	), model_dependencies(package_ea_guid, package_id, package_name) AS (
	SELECT DISTINCT
		package_ea_guid,
		package_id,
		package_name
	FROM
		attribute_type_conceptual_schema_or_standard_info
	), package_dependency_diagrams(diagram_ea_guid, diagram_type, diagram_id, diagram_name, package_ea_guid, package_id, package_name) AS (
	SELECT
        d.ea_guid,
        d.diagram_type,
        d.diagram_id,
        d.name,
		p.ea_guid,
		p.package_id,
		p.name
    FROM
        t_diagram d
	INNER JOIN t_package p ON
		d.package_id = p.package_id
    WHERE
        d.package_id IN (#Branch#)
        AND d.name = #Concat '<Search Term> ', p.name#
	)
	SELECT
		pdd.diagram_ea_guid AS CLASSGUID,
		pdd.diagram_type AS CLASSTYPE,
		't_diagram' AS CLASSTABLE,
		pdd.diagram_name,
		#Concat '"', p.name , '" is not a model dependency'# AS info
	FROM
		package_dependency_diagrams pdd,
		t_package p
	WHERE
		EXISTS (
		SELECT
			*
		FROM
			t_diagramobjects do
		INNER JOIN t_object o ON	
			do.object_id = o.object_id
		WHERE
			do.diagram_id = pdd.diagram_id
			AND o.ea_guid = p.ea_guid
			AND p.package_id <> #Package#
			AND p.ea_guid NOT IN (
			SELECT
				package_ea_guid
			FROM
				model_dependencies)
		)
	UNION ALL
	SELECT
		pdd.diagram_ea_guid,
		pdd.diagram_type,
		't_diagram',
		pdd.diagram_name,
		#Concat 'The connector of type "', c.connector_type , '" between "', o_start.name , '" and ', o_end.name , '" must not be present'#
	FROM
		package_dependency_diagrams pdd,
		(t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	WHERE
		EXISTS (
		SELECT
			*
		FROM
			t_diagramlinks dl
		WHERE
			dl.diagramid = pdd.diagram_id
			AND dl.connectorid = c.connector_id
			AND (o_start.ea_guid = pdd.package_ea_guid
				OR o_end.ea_guid = pdd.package_ea_guid)
			AND c.connector_type NOT IN ('Usage', 'NoteLink')
		)
);

```

## `diagrams_with_associations_with_inconsistent_reading_directions`

 Finds the diagrams that contain associations whose reading directions are inconsistent across diagrams. Only diagrams where both the association and its name are visible are taken into account. This query is useful because EA stores the reading direction of an association in t_diagramlinks, not in t_connector. 

```sql
SELECT
	*
FROM
	(
WITH
	labelsetposition(diagramid, connectorid, connector_is_hidden, position, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        hidden,
		instr(geometry, '$'),
		geometry
	FROM
		t_diagramlinks),
	labelset(diagramid, connectorid, connector_is_hidden, text, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		ltrim(substr(geometry, position), '$'),
		geometry
	FROM
		labelsetposition
	WHERE
		position > 0),
	middletoplabelplus(diagramid, connectorid, connector_is_hidden, text, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		substr(text, instr(text, 'LMT=')),
		geometry
	FROM
		labelset),
	middletoplabel(diagramid, connectorid, connector_is_hidden, text, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		substr(text, 1, instr(text, ';') - 1),
		geometry
	FROM
		middletoplabelplus),
	diagramlinkviewplus(diagramid, connectorid, connector_is_hidden, label_is_hiddenplus, directionplus) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		substr(text, instr(text, 'HDN=')),
		substr(text, instr(text, 'DIR='))
	FROM
		middletoplabel
	WHERE
		text <> 'LMT='),
	diagramlinkview(diagramid, connectorid, connector_is_hidden, label_is_hidden, direction) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		CAST(substr(label_is_hiddenplus, 5, instr(label_is_hiddenplus, ':') - 5) AS INTEGER),
		CAST(substr(directionplus, 5, instr(directionplus, ':') - 5) AS INTEGER)
	FROM
		diagramlinkviewplus),
	diagrams_with_visible_association_labels(diagram_ea_guid, diagram_type, diagram_id, diagram_name, connector_id, connector_name, reading_direction) AS (
	SELECT
		d.ea_guid,
		d.diagram_type,
		d.diagram_id,
		d.name,
		c.connector_id,
		c.name,
		dl.direction
	FROM
		(diagramlinkview dl
	INNER JOIN t_diagram d ON
		dl.diagramid = d.diagram_id)
	INNER JOIN t_connector c ON
		dl.connectorid = c.connector_id
	WHERE
		d.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation')
				AND d.styleex NOT LIKE '%SuppConnectorLabels=1%'
				AND d.pdata NOT LIKE '%HideRel=1%'
				AND dl.connector_is_hidden = 0
				AND dl.label_is_hidden = 0
	)
	SELECT
		diagram_ea_guid AS CLASSGUID,
		diagram_type AS CLASSTYPE,
		't_diagram' AS CLASSTABLE,
		connector_name AS association_name,
		CASE
			WHEN reading_direction = -1 THEN 'To Source'
			WHEN reading_direction = 0 THEN 'No Indicator'
			WHEN reading_direction = 1 THEN 'To Destination'
		END AS association_reading_direction,
		diagram_name
	FROM
		diagrams_with_visible_association_labels d
	WHERE
		connector_id IN (
		SELECT
			connector_id
		FROM
			diagrams_with_visible_association_labels
		GROUP BY
			connector_id
		HAVING
			count(DISTINCT reading_direction) > 1)
	ORDER BY
		association_name,
		diagram_name
)
;

```

## `diagrams_with_associations_with_unspecified_reading_directions`

 Finds the diagrams that contain associations whose reading direction is unspecified. Only diagrams where both the association and its name are visible are taken into account. This query is useful because EA stores the reading direction of an association in t_diagramlinks, not in t_connector. 

```sql
SELECT
	*
FROM
	(
WITH
	labelsetposition(diagramid, connectorid, connector_is_hidden, position, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        hidden,
		instr(geometry, '$'),
		geometry
	FROM
		t_diagramlinks),
	labelset(diagramid, connectorid, connector_is_hidden, text, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		ltrim(substr(geometry, position), '$'),
		geometry
	FROM
		labelsetposition
	WHERE
		position > 0),
	middletoplabelplus(diagramid, connectorid, connector_is_hidden, text, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		substr(text, instr(text, 'LMT=')),
		geometry
	FROM
		labelset),
	middletoplabel(diagramid, connectorid, connector_is_hidden, text, geometry) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		substr(text, 1, instr(text, ';') - 1),
		geometry
	FROM
		middletoplabelplus),
	diagramlinkviewplus(diagramid, connectorid, connector_is_hidden, label_is_hiddenplus, directionplus) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		substr(text, instr(text, 'HDN=')),
		substr(text, instr(text, 'DIR='))
	FROM
		middletoplabel
	WHERE
		text <> 'LMT='),
	diagramlinkview(diagramid, connectorid, connector_is_hidden, label_is_hidden, direction) AS (
	SELECT
		diagramid,
		connectorid,
        connector_is_hidden,
		CAST(substr(label_is_hiddenplus, 5, instr(label_is_hiddenplus, ':') - 5) AS INTEGER),
		CAST(substr(directionplus, 5, instr(directionplus, ':') - 5) AS INTEGER)
	FROM
		diagramlinkviewplus),
	diagrams_with_visible_association_labels(diagram_ea_guid, diagram_type, diagram_id, diagram_name, connector_id, connector_name, reading_direction) AS (
	SELECT
		d.ea_guid,
		d.diagram_type,
		d.diagram_id,
		d.name,
		c.connector_id,
		c.name,
		dl.direction
	FROM
		(diagramlinkview dl
	INNER JOIN t_diagram d ON
		dl.diagramid = d.diagram_id)
	INNER JOIN t_connector c ON
		dl.connectorid = c.connector_id
	WHERE
		d.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation')
				AND d.styleex NOT LIKE '%SuppConnectorLabels=1%'
				AND d.pdata NOT LIKE '%HideRel=1%'
				AND dl.connector_is_hidden = 0
				AND dl.label_is_hidden = 0
	)
	SELECT
		diagram_ea_guid AS CLASSGUID,
		diagram_type AS CLASSTYPE,
		't_diagram' AS CLASSTABLE,
		connector_name AS association_name,
		diagram_name
	FROM
		diagrams_with_visible_association_labels d
	WHERE
		length(connector_name) > 0
		AND reading_direction = 0
	ORDER BY
		association_name,
		diagram_name
)
;

```

## `diagrams_with_diagramdetails`

 Find the diagrams that show the diagram details (see also https://sparxsystems.com/eahelp/appearance_options_diag.html). 

```sql
SELECT
	d.ea_guid AS CLASSGUID,
	d.diagram_type AS CLASSTYPE,
	't_diagram' AS CLASSTABLE,
	d.name
FROM
	t_diagram d
WHERE
	d.package_id IN (#Branch#)
	AND d.showdetails = 1;

```

## `diagrams_with_diagramnotes`

 Find the diagrams that contains diagram notes, also called a diagram properties note (see https://sparxsystems.com/eahelp/addpropertiesnote.html). 

```sql
SELECT
	d.ea_guid AS CLASSGUID,
	d.diagram_type AS CLASSTYPE,
	't_diagram' AS CLASSTABLE,
	d.name
FROM
	t_diagram d
WHERE
	d.package_id IN (#Branch#)
	AND EXISTS
(
	SELECT
		*
	FROM
		t_diagramobjects do
	INNER JOIN t_object o ON
		o.object_id = do.object_id
	WHERE
		do.diagram_id = d.diagram_id
		AND o.ntype = 18);

```

## `diagrams_with_invalid_names_da`

 The names of the diagrams have to follow a specific pattern to be able to create a good feature catalogue. The name must start with one of the following (Danish): 'Pakkeafhængigheder', 'Subpakker', 'Oversigtsdiagram' or 'Kontekstdiagram'. The part of the name after 'Kontekstdiagram' must be equal to the name of an existing object in the model that the diagram resides in, if the diagram's name starts with 'Kontekstdiagram'.  

```sql
SELECT
	d.ea_guid AS CLASSGUID,
	d.diagram_type AS CLASSTYPE,
	't_diagram' AS CLASSTABLE,
	d.name
FROM
	t_diagram d
INNER JOIN t_package p ON
	d.package_id = p.package_id
WHERE
	d.package_id IN (#Branch#)
	AND d.name <> #Concat 'Pakkeafhængigheder ', p.name#
	AND d.name <> #Concat 'Subpakker ', p.name#
	AND #Substring d.name, 1, 16# <> 'Oversigtsdiagram'
	AND #Substring d.name, 1, 15# <> 'Kontekstdiagram'
UNION ALL
SELECT
	d.ea_guid AS CLASSGUID,
	d.diagram_type AS CLASSTYPE,
	't_diagram' AS CLASSTABLE,
	d.name
FROM
	t_diagram d
WHERE
	d.package_id IN (#Branch#)
	AND d.name LIKE 'Kontekstdiagram%'
	AND NOT EXISTS (
	SELECT
		1
	FROM
		t_object o
	WHERE
		o.package_id IN (#Branch#)
			AND #Substring d.name, 17# = o.name)
ORDER BY
	2;

```

## `diagrams_with_invalid_names_en`

 The names of the diagrams have to follow a specific pattern to be able to create a good feature catalogue. The name must start with one of the following (English): 'Package dependencies', 'Subpackages', 'Overview diagram' or 'Context diagram'. The part of the name after 'Context diagram' must be equal to the name of an existing object in the model that the diagram resides in, if the diagram's name starts with 'Context diagram'.  

```sql
SELECT
	d.ea_guid AS CLASSGUID,
	d.diagram_type AS CLASSTYPE,
	't_diagram' AS CLASSTABLE,
	d.name
FROM
	t_diagram d
INNER JOIN t_package p ON
	d.package_id = p.package_id
WHERE
	d.package_id IN (#Branch#)
	AND d.name <> #Concat 'Package dependencies ', p.name#
	AND d.name <> #Concat 'Subpackages ', p.name#
	AND #Substring d.name, 1, 16# <> 'Overview diagram'
	AND #Substring d.name, 1, 15# <> 'Context diagram'
UNION ALL
SELECT
	d.ea_guid AS CLASSGUID,
	d.diagram_type AS CLASSTYPE,
	't_diagram' AS CLASSTABLE,
	d.name
FROM
	t_diagram d
WHERE
	d.package_id IN (#Branch#)
	AND d.name LIKE 'Context diagram%'
	AND NOT EXISTS (
	SELECT
		1
	FROM
		t_object o
	WHERE
		o.package_id IN (#Branch#)
			AND #Substring d.name, 17# = o.name)
ORDER BY
	2;

```

## `duplicate_attributes_classifier`

 Find the owned and inherited attributes of the classifier selected in the Project Browser that have the same name as another attribute of that classifier. Association ends are not taken into account. Note: the query contains "level * 2" instead of the usual "level + 1". This is because there is a bug in EA that causes numeric addition not to work, see also https://sparxsystems.com/forums/smf/index.php/topic,48040.0.html. 

```sql
SELECT
	*
FROM
	(
WITH self_and_ancestor(object_id,
	name,
	level) AS (
	SELECT
		o.object_id,
		o.name,
		1
	FROM
		t_object o
	WHERE
		o.object_id = #CurrentElementID#
UNION ALL
	SELECT
		o_parent.object_id,
		o_parent.name,
		s.level * 2
	FROM
		(self_and_ancestor s
	INNER JOIN t_connector c ON
		(s.object_id = c.start_object_id
			AND c.connector_type = 'Generalization'))
	INNER JOIN t_object o_parent ON
		c.end_object_id = o_parent.object_id
),
	attributes_self_and_ancestor(CLASSGUID,
	CLASSTYPE,
	property_name,
	defining_classifier_object_id,
	defining_classifier_name,
	level) AS (
	SELECT
		a.ea_guid,
		'Attribute',
		a.name,
		o.object_id,
		o.name,
		o.level
	FROM
		t_attribute a
	INNER JOIN
	self_and_ancestor o
ON
		a.object_id = o.object_id
	)
	SELECT
		CLASSGUID,
		CLASSTYPE,
		a1.property_name,
		defining_classifier_name
	FROM
		(
		SELECT
			*
		FROM
			attributes_self_and_ancestor) a1
	INNER JOIN
	(
		SELECT
			property_name
		FROM
			attributes_self_and_ancestor
		GROUP BY
			property_name
		HAVING
			COUNT(*) > 1) a2 ON
		a1.property_name = a2.property_name
)

```

## `enumeration_literals_attributes_with_stereotype_enum`

 Find the enumeration attributes and literals defined that have stereotype "enum". See also https://sparxsystems.com/forums/smf/index.php/topic,39483.msg243694.html#msg243694. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS enumeration_name,
	a.name AS attribute_or_literal_name,
	a.styleex,
	a.stereotype AS primary_unqualified_stereotype,
	x.description AS stereotypes
FROM
	((t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_package p ON
	o.package_id = p.package_id)
LEFT JOIN t_xref x ON
	a.ea_guid = x.client
	AND x.name = 'Stereotypes'
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type = 'Enumeration'
	AND x.description LIKE '%Name=enum;%';

```

## `enumeration_literals_two_consecutive_spaces`

 Find the enumeration literals whose name has two consecutive spaces. The occurrence of two consecutive spaces is very likely an error. 

```sql
SELECT
		a.ea_guid AS CLASSGUID,
		'Attribute' AS CLASSTYPE,
		p.name AS package_name,
		o.name AS classifier_name,
		a.name AS enumeration_literal_name
FROM
		(t_attribute a
INNER JOIN t_object o ON
		a.object_id = o.object_id)
INNER JOIN t_package p ON
		o.package_id = p.package_id
WHERE
		o.package_id IN (#Branch#)
	AND o.object_type IN ('Enumeration')
	AND a.name LIKE '%  %'
ORDER BY
	package_name,
	classifier_name,
	enumeration_literal_name;

```

## `enumeration_literals_with_duplicate_names`

 Find the enumeration literals that have the same name as another enumeration literal of the same enumeration. See also the UML 2.5.1 specification, clause 10.2.3.3: An EnumerationLiteral has a name that shall be used to identify it within its Enumeration. The EnumerationLiteral name is scoped within and shall be unique within its Enumeration. 

```sql
SELECT
		a.ea_guid AS CLASSGUID,
		'Attribute' AS CLASSTYPE,
		p.name AS package_name,
		o.name AS classifier_name,
		a.name AS enumeration_literal_name
FROM
		(t_attribute a
INNER JOIN t_object o ON
		a.object_id = o.object_id)
INNER JOIN t_package p ON
		o.package_id = p.package_id
WHERE
		o.package_id IN (#Branch#)
	AND o.object_type IN ('Enumeration')
	AND EXISTS (
	SELECT
		*
	FROM
		t_attribute a2
	WHERE
		a2.object_id = a.object_id
		AND a2.name = a.name
		AND a2.ea_guid <> a.ea_guid )
ORDER BY
	package_name,
	classifier_name,
	enumeration_literal_name;

```

## `model_dependencies`

 Finds all conceptual schemas or standards that a model depends on. 

```sql
SELECT * FROM (
	WITH RECURSIVE conceptual_schema_or_standard(package_ea_guid, package_id, name, stereotype) AS (
	SELECT 
		p.ea_guid,
		p.package_id,
		p.name,
		o.stereotype
	FROM
		t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid
	WHERE
		o.stereotype IN ('DKDomænemodel', 'AbstractSchema', 'ApplicationSchema')
		OR (
		 EXISTS (
			SELECT
				*
			FROM
				t_objectproperties op
			WHERE
				op.object_id = o.object_id
				AND lower(op.property) = 'isapplicationsschema'
				AND op.value = 'true')
		)
		OR (
			EXISTS (
				SELECT
					*
				FROM
					t_objectproperties op
				WHERE
					op.object_id = o.object_id
					AND op.property = 'name'
					AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'number'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'yearVersion'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'publicationDate'
						AND LENGTH(op.value) > 0)
		)
	), attribute_type(type_id, type_name, type_package_id) AS (
		SELECT DISTINCT
			t.object_id,
			t.name,
			t.package_id
		FROM
			t_object o
		INNER JOIN t_attribute a ON
			o.object_id = a.object_id
		INNER JOIN t_object t ON
			a.classifier = t.object_id
		WHERE
			o.package_id IN (#Branch#)
			AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
			AND instr(a.styleex, 'IsLiteral=1') = 0
			AND t.package_id <> o.package_id
	), attribute_type_package_info(type_id, type_name, package_ea_guid, package_id, package_name, parent_id, level) AS (
		SELECT
			attribute_type.type_id,
			attribute_type.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			1
		FROM
			attribute_type
		INNER JOIN t_package p
			ON attribute_type.type_package_id = p.package_id
	UNION ALL
		SELECT
			atpi.type_id,
			atpi.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			atpi.level * 2
		FROM
			attribute_type_package_info atpi
			INNER JOIN t_package p ON
				atpi.parent_id = p.package_id
		WHERE atpi.package_id NOT IN (SELECT package_id FROM conceptual_schema_or_standard)
	), attribute_type_conceptual_schema_or_standard_info(type_id, type_name, package_ea_guid, package_id, package_name) AS (
		SELECT
			type_id,
			type_name,
			package_ea_guid,
			package_id,
			package_name
		FROM
			attribute_type_package_info atpi
		WHERE level = (
				SELECT max(level)
				FROM attribute_type_package_info AS atpi2
				WHERE atpi2.type_id = atpi.type_id
			)
	), model_dependencies(package_ea_guid, package_id, package_name) AS (
	SELECT DISTINCT
		package_ea_guid,
		package_id,
		package_name
	FROM
		attribute_type_conceptual_schema_or_standard_info
	)
	SELECT
		package_ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		package_id,
		package_name
	FROM
		model_dependencies
);

```

## `model_element_by_guid`

 Find the model elements with the given GUID. Both the internal GUID format and the XML format are recognized. 

```sql
SELECT
	*
FROM
	(
WITH guid(internal_guid) AS 
	(
	SELECT
		CASE
			WHEN SUBSTR('<Search Term>', 1, 2) = 'EA' THEN
				'{' || REPLACE(SUBSTR('<Search Term>', 6), '_', '-' ) || '}'
			ELSE '<Search Term>'
		END
	)
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS name,
		'Package' AS type,
		p.ea_guid AS ea_guid
	FROM
		t_package p
	WHERE
		p.ea_guid = (
		SELECT
			internal_guid
		FROM
			guid)
UNION
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		o.name,
		o.object_type,
		o.ea_guid
	FROM
		t_object o
	WHERE
		o.ea_guid = (
		SELECT
			internal_guid
		FROM
			guid)
UNION
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		a.name,
		CASE
			WHEN a.styleex LIKE '%IsLiteral=1%' THEN
				'EnumerationLiteral'
			ELSE 'Attribute'
		END,
		a.ea_guid
	FROM
		t_attribute a
	WHERE
		a.ea_guid = (
		SELECT
			internal_guid
		FROM
			guid)
UNION
	SELECT
		c.ea_guid,
		c.connector_type,
		't_connector',
		c.name,
		c.connector_type,
		c.ea_guid
	FROM
		t_connector c
	WHERE
		c.ea_guid = (
		SELECT
			internal_guid
		FROM
			guid)
UNION
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		c.destrole,
		'AssociationEnd',
		NULL
	FROM
		t_connector c
	WHERE
		c.ea_guid LIKE (
		SELECT
			REPLACE(internal_guid, 'dst', '%')
		FROM
			guid)
UNION
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		c.sourcerole,
		'AssociationEnd',
		NULL
	FROM
		t_connector c
	WHERE
		c.ea_guid LIKE (
		SELECT
			REPLACE(internal_guid, 'src', '%')
		FROM
			guid)
UNION
	SELECT
		d.ea_guid,
		d.diagram_type,
		't_diagram',
		d.name,
		d.diagram_type,
		d.ea_guid
	FROM
		t_diagram d
	WHERE
		d.ea_guid = (
		SELECT
			internal_guid
		FROM
			guid)
)
;

```

## `model_elements_by_fq_stereotype`

 Finds the models elements that have the given fully qualified stereotype name. Comparison of the search term and the model elements stereotypes is done case-sensitively. For more information about the returned columns, see query model_elements_stereotypes. 

```sql
SELECT
	*
FROM
	(
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS package_name,
		NULL AS classifier_name,
		NULL AS property_name,
		o.stereotype AS primary_unqualified_stereotype,
		x.description AS stereotypes
	FROM
		(t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		p.package_id IN (#Branch#)
	UNION ALL
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		p.name,
		o.name,
		NULL,
		o.stereotype,
		x.description
	FROM
		(t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.stereotype,
		x.description
	FROM
		((t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		a.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.deststereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	LEFT JOIN t_xref x
		ON x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorDestEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
	UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcestereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	LEFT JOIN t_xref x
		ON x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorSrcEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
	)
WHERE
	stereotypes GLOB '*;FQName=<Search Term>;*'
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_by_unq_stereotype`

 Finds the models elements that have the given stereotype name. Comparison of the search term and the model elements stereotypes is done case-insensitively, and the search term is expected to be an unqualified stereotype name. For more information about the returned columns, see query model_elements_stereotypes. 

```sql
SELECT
	*
FROM
	(
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS package_name,
		NULL AS classifier_name,
		NULL AS property_name,
		o.stereotype AS primary_unqualified_stereotype,
		x.description AS stereotypes
	FROM
		(t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		p.package_id IN (#Branch#)
	UNION ALL
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		p.name,
		o.name,
		NULL,
		o.stereotype,
		x.description
	FROM
		(t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.stereotype,
		x.description
	FROM
		((t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		a.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.deststereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	LEFT JOIN t_xref x
		ON x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorDestEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
	UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcestereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	LEFT JOIN t_xref x
		ON x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorSrcEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
	)
WHERE
	lower(primary_unqualified_stereotype) = lower('<Search Term>')
	OR lower(stereotypes) GLOB lower('*;Name=<Search Term>;*')
	OR lower(stereotypes) GLOB lower('*;FQName=[^:]*::<Search Term>;*')
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_compare_tagged_value_alias`

 Finds all model elements in a package and displays (1) their alias, if set and (2) the value they have for the given tagged value (typically "dbName"), if set. The actual value is only displayed for tagged values that are not of the memo type. This query is useful for models where the aliases of the model elements are supposed to be the same as values of the tag (it is possible to configure to show names and/or aliases on diagrams, but not single tags, this approach is a workaround). 

```sql
SELECT
	*
FROM
	(
WITH aliasconnectorend AS (
	SELECT
		connector_id,
		CASE
			WHEN INSTR(sourcestyle, 'alias=') > 0 THEN
        SUBSTR(
          sourcestyle,
          INSTR(sourcestyle, 'alias=') - (-6),
          INSTR(SUBSTR(sourcestyle, INSTR(sourcestyle, 'alias=') - (-6)), ';') - 1
        )
			ELSE NULL
		END AS sourcealias,
		CASE
			WHEN INSTR(deststyle, 'alias=') > 0 THEN
        SUBSTR(
          deststyle,
          INSTR(deststyle, 'alias=') - (-6),
          INSTR(SUBSTR(deststyle, INSTR(deststyle, 'alias=') - (-6)), ';') - 1
        )
			ELSE NULL
		END AS destalias
	FROM
		t_connector
)
	SELECT
		o.ea_guid AS CLASSGUID,
		o.object_type AS CLASSTYPE,
		NULL AS CLASSTABLE,
		o.name AS name,
		p.name AS namespace,
		op.value AS "<Search Term>",
		o.alias AS alias
	FROM
		(t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_objectproperties op ON
		op.object_id = o.object_id
		AND op.property = ('<Search Term>')
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		a.name,
		o.name,
		at.value,
		a.style
	FROM
		(t_attribute a
	INNER JOIN t_object o ON
		o.object_id = a.object_id
	INNER JOIN t_package p ON
		p.package_id = o.package_id)
	LEFT JOIN t_attributetag AT ON
		a.id = at.elementid
		AND at.property = '<Search Term>'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		c.destrole,
		o_start.name,
		tv.notes,
		ace.destalias
	FROM
		(t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	INNER JOIN aliasconnectorend ace ON
		c.connector_id = ace.connector_id)
	LEFT JOIN t_taggedvalue tv ON
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = '<Search Term>'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Source -> Destination', 'Bi-Directional')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		c.sourcerole,
		o_end.name,
		tv.notes,
		ace.sourcealias
	FROM
		(t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	INNER JOIN aliasconnectorend ace ON
		c.connector_id = ace.connector_id)
	LEFT JOIN t_taggedvalue tv ON
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = '<Search Term>'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Destination -> Source', 'Bi-Directional')
)
ORDER BY
	namespace,
	name;

```

## `model_elements_custom_stereotype`

 Show the model elements with a custom stereotype, that is a stereotype that is (or at some point was) defined in the project's reference data. See also https://sparxsystems.com/eahelp/creatingcustomstereotypes.html, table t_stereotypes and query stereotypes. This query is closely related to model_elements_stereotype_not_from_profile. Usually, this query and model_elements_stereotype_not_from_profile will return the same results. However, model elements with a stereotype stored as @STEREO;Name=DKEgenskab;GUID={16570901-9E07-4319-81A7-25B52F03CF74};FQName=Grunddata::DKEgenskab;@ENDSTEREO have been seen in certain models, therefore the split into two queries. 

```sql
SELECT
	*
FROM
	(
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS package_name,
		NULL AS classifier_name,
		NULL AS property_name,
		o.stereotype AS primary_unqualified_stereotype,
		x.description AS stereotypes
	FROM
		(t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		p.package_id IN (#Branch#)
UNION ALL
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		p.name,
		o.name,
		NULL,
		o.stereotype,
		x.description
	FROM
		(t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.stereotype,
		x.description
	FROM
		((t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		a.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.deststereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorDestEnd property'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcestereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorSrcEnd property'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
)
WHERE
	stereotypes LIKE '%GUID%'
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_duplicate_tags`

 Find the packages, classifiers, properties, enumeration literals and relationships that have more than one tagged value with the same name. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS element_name,
	op.property AS tag_name
FROM
	(t_objectproperties op
INNER JOIN t_object o ON
	op.object_id = o.object_id)
INNER JOIN t_package p ON
	p.ea_guid = o.ea_guid
WHERE
	p.package_id IN (#Branch#)
	AND o.object_type IN ('Package')
GROUP BY
	o.ea_guid,
	o.object_type,
	o.name,
	op.property
HAVING
	count(op.property) > 1
UNION ALL
SELECT
	o.ea_guid,
	o.object_type,
	NULL,
	o.name,
	op.property
FROM
	t_objectproperties op
INNER JOIN t_object o ON
	op.object_id = o.object_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Interface', 'Enumeration')
GROUP BY
	o.ea_guid,
	o.object_type,
	o.name,
	op.property
HAVING
	count(op.property) > 1
UNION ALL
SELECT
	a.ea_guid,
	'Attribute',
	NULL,
	a.name,
	at.property
FROM
	(t_attributetag AT
INNER JOIN t_attribute a ON
	at.elementid = a.id)
INNER JOIN t_object o ON
	a.object_id = o.object_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Interface', 'Enumeration')
GROUP BY
	a.ea_guid,
	a.name,
	at.property
HAVING
	count(at.property) > 1
UNION ALL
SELECT
	c.ea_guid,
	c.connector_type,
	't_connector',
	c.name,
	ct.property
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_connectortag ct ON
	ct.elementid = c.connector_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
GROUP BY
	c.ea_guid,
	c.connector_type,
	c.name,
	ct.property
HAVING
	count(ct.property) > 1
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.sourcerole,
	tv.tagvalue
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
GROUP BY
	c.ea_guid,
	c.connector_type,
	c.sourcerole,
	tv.tagvalue
HAVING
	count(tv.tagvalue) > 1
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.destrole,
	tv.tagvalue
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
GROUP BY
	c.ea_guid,
	c.connector_type,
	c.destrole,
	tv.tagvalue
HAVING
	count(tv.tagvalue) > 1;

```

## `model_elements_gisname_transliteratedname_gmlname`

 Finds all classifiers and properties and the values of tags gisName, transliteratedName and gmlName. The query only works for tagged values that are not of the memo type. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS name,
	p.name AS namespace,
		(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'gisName') AS gisName,
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'gmlName') AS gmlName
FROM
	t_object o
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	a.ea_guid,
	'Attribute',
	NULL,
	a.name,
	o.name,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'gisName') AS gisName,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'gmlName') AS gmlName
FROM
		((t_attribute a
INNER JOIN t_object o ON
		o.object_id = a.object_id)
INNER JOIN t_package p ON
		p.package_id = o.package_id)
WHERE
		o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	AND a.styleex NOT LIKE '%IsLiteral=1%'
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.destrole,
	o_start.name,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'gisName') AS gisName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'gmlName') AS gmlName
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.sourcerole,
	o_end.name,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'gisName') AS gisName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'gmlName') AS gmlName
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional')
;

```

## `model_elements_invalid_names_internal`

 Finds the classifiers, properties and enumeration literals with names having characters that are invalid according to the internal rules of the agency. In addition, in both XML and databases, the first character of a name must be alphabetic, and thus not start with a digit. To ease conversion to XML and database schemas, the first character of a name in the model has to be alphabetic as well. The latter rule does not apply to enumeration literals. 

```sql
SELECT
	*
FROM
	(
	SELECT
		o.ea_guid AS CLASSGUID,
		o.object_type AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS package_name,
		o.name AS classifier_name,
		NULL AS property_or_enumeration_literal_name,
		o.name AS element_name
	FROM
		t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.name
	FROM
		(t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Interface')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.destrole
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcerole
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong')))
WHERE
	(element_name GLOB '*[^a-zA-ZæøåéÆØÅÉ0-9_]*'
		OR element_name NOT GLOB '[a-zA-ZæøåéÆØÅÉ]*')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.name
FROM
		(t_attribute a
INNER JOIN t_object o ON
		a.object_id = o.object_id)
INNER JOIN t_package p ON
		o.package_id = p.package_id
WHERE
		o.package_id IN (#Branch#)
	AND o.object_type IN ('Enumeration')
	AND a.name GLOB '*[^a-zA-ZæøåéÆØÅÉ0-9Ωαβ, .():+''>=<&§/_%-]*'
ORDER BY
	package_name,
	classifier_name,
	property_or_enumeration_literal_name;

```

## `model_elements_nonpublic_scope`

 Finds the model elements that do not have their scope set to "Public". 

```sql
SELECT * FROM (
SELECT
	p.ea_guid AS CLASSGUID,
	'Package' AS CLASSTYPE,
	NULL AS CLASSTABLE,
	p.Name AS package_name,
	NULL AS classifier_name,
	NULL AS property_name,
	o.scope AS scope
FROM
	t_package p
INNER JOIN t_object o ON
	p.ea_guid = o.ea_guid
WHERE
	p.package_id IN (#Branch#)
UNION ALL
SELECT
	o.ea_guid,
	o.object_type,
	NULL,
	p.name,
	o.name AS classifier_name,
	NULL AS property_name,
	o.scope
FROM
	t_object o
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	a.ea_guid,
	'Attribute',
	NULL,
	p.name,
	o.name,
	a.name,
	a.scope
FROM
	(t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_start.name,
	o_start.name,
	c.destrole,
	c.destaccess
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_start ON
	o_start.package_id = p_start.package_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_end.name,
	o_end.name,
	c.sourcerole,
	c.sourceaccess
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_end ON
	o_end.package_id = p_end.package_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional')))
	WHERE scope <> 'Public'
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_notes`

 Shows the notes on model elements. 

```sql
SELECT
	p.ea_guid AS CLASSGUID,
	'Package' AS CLASSTYPE,
	NULL AS CLASSTABLE,
	p.Name AS package_name,
	NULL AS classifier_name,
	NULL AS property_name,
	o.note AS notes
FROM
	t_package p
INNER JOIN t_object o ON
	p.ea_guid = o.ea_guid
WHERE
	p.package_id IN (#Branch#)
UNION ALL
SELECT
	o.ea_guid,
	o.object_type,
	NULL,
	p.name,
	o.name AS classifier_name,
	NULL AS property_name,
	o.note AS notes
FROM
	t_object o
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	a.ea_guid,
	'Attribute',
	NULL,
	p.name,
	o.name,
	a.name,
	a.notes
FROM
	(t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_start.name,
	o_start.name,
	c.destrole,
	c.destrolenote AS notes
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_start ON
	o_start.package_id = p_start.package_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_end.name,
	o_end.name,
	c.sourcerole,
	c.sourcerolenote
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_end ON
	o_end.package_id = p_end.package_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_notes_not_null_not_empty`

 Finds the model elements with a note that is not null and not empty. Note: When creating a new attribute (https://sparxsystems.com/eahelp/attributesmainpage.html), its note is null until something is written into it. However, when copying an attribute from another classifier (https://sparxsystems.com/eahelp/copyingattributes.html), the note of the copy is NOT null, it is an empty string. But then again, when importing a model from XMI in another project file, all notes are null, even though the attributes originally were copied. Anyway, this explains the WHERE clause. 

```sql
SELECT
	*
FROM
	(
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.Name AS package_name,
		NULL AS classifier_name,
		NULL AS property_name,
		o.note AS notes
	FROM
		t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid
	WHERE
		p.package_id IN (#Branch#)
UNION ALL
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		p.name,
		o.name AS classifier_name,
		NULL AS property_name,
		o.note AS notes
	FROM
		t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.notes
	FROM
		(t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.destrolenote AS notes
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcerolenote
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
	)
WHERE
	(notes IS NOT NULL AND LENGTH(notes) > 0)
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_oraclename_transliteratedname_dbname`

 Finds all classifiers and properties and the values of tags oracleName, transliteratedName and dbName. The query only works for tagged values that are not of the memo type. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS name,
	p.name AS namespace,
		(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'oracleName') AS oracleName,
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'dbName') AS dbName
FROM
	t_object o
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	a.ea_guid,
	'Attribute',
	NULL,
	a.name,
	o.name,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'oracleName') AS oracleName,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			at.value
	FROM
			t_attributetag at
	WHERE
			a.id = at.elementid
		AND at.property = 'dbName') AS dbName
FROM
		((t_attribute a
INNER JOIN t_object o ON
		o.object_id = a.object_id)
INNER JOIN t_package p ON
		p.package_id = o.package_id)
WHERE
		o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	AND a.styleex NOT LIKE '%IsLiteral=1%'
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.destrole,
	o_start.name,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'oracleName') AS oracleName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'dbName') AS dbName
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.sourcerole,
	o_end.name,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'oracleName') AS oracleName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'transliteratedName') AS transliteratedName,
	(
	SELECT
			tv.notes
	FROM
			t_taggedvalue tv
	WHERE
			tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'dbName') AS dbName
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional')
;

```

## `model_elements_stereotype_basicdata1`

 Show the model elements with a stereotype that is defined in the Basic Data 1 profile. See also query stereotypes. 

```sql
SELECT
	*
FROM
	(
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS package_name,
		NULL AS classifier_name,
		NULL AS property_name,
		o.stereotype AS primary_unqualified_stereotype,
		x.description AS stereotypes
	FROM
		(t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		p.package_id in (#Branch#)
UNION ALL
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		p.name,
		o.name,
		NULL,
		o.stereotype,
		x.description
	FROM
		(t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.stereotype,
		x.description
	FROM
		((t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		a.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.deststereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorDestEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcestereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorSrcEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
)
WHERE
	(stereotypes LIKE '%FQName=Grunddata::%')
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_stereotype_not_basicdata2`

 Show the model elements with a stereotype that is not defined in the Basic Data 2 profile and that are not a subpackage of the selected model. See also query stereotypes. 

```sql
SELECT
	*
FROM
	(
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS package_name,
		NULL AS classifier_name,
		NULL AS property_name,
		o.stereotype AS primary_unqualified_stereotype,
		x.description AS stereotypes
	FROM
		(t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		p.package_id = #Package#
UNION ALL
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		p.name,
		o.name,
		NULL,
		o.stereotype,
		x.description
	FROM
		(t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.stereotype,
		x.description
	FROM
		((t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		a.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.deststereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorDestEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcestereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorSrcEnd property'
	WHERE
		(((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
)
WHERE
	(stereotypes IS NULL
		OR stereotypes NOT LIKE '%FQName=Grunddata2::%')
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_stereotype_not_from_profile`

 Show the model elements with a stereotype that is not defined in a UML profile and that are not a subpackage of the selected model. See also query stereotypes. 

```sql
SELECT
	*
FROM
	(
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		NULL AS CLASSTABLE,
		p.name AS package_name,
		NULL AS classifier_name,
		NULL AS property_name,
		o.stereotype AS primary_unqualified_stereotype,
		x.description AS stereotypes
	FROM
		(t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		p.package_id = #Package#
UNION ALL
	SELECT
		o.ea_guid,
		o.object_type,
		NULL,
		p.name,
		o.name,
		NULL,
		o.stereotype,
		x.description
	FROM
		(t_object o
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		o.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		a.ea_guid,
		'Attribute',
		NULL,
		p.name,
		o.name,
		a.name,
		a.stereotype,
		x.description
	FROM
		((t_attribute a
	INNER JOIN t_object o ON
		a.object_id = o.object_id)
	INNER JOIN t_package p ON
		o.package_id = p.package_id)
	LEFT JOIN t_xref x ON
		a.ea_guid = x.client
		AND x.name = 'Stereotypes'
	WHERE
		o.package_id IN (#Branch#)
		AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_start.name,
		o_start.name,
		c.destrole,
		c.deststereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_start ON
		o_start.package_id = p_start.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorDestEnd property'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
UNION ALL
	SELECT
		c.ea_guid,
		'AssociationEnd',
		't_connector',
		p_end.name,
		o_end.name,
		c.sourcerole,
		c.sourcestereotype,
		x.description
	FROM
		((t_connector c
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id)
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id)
	INNER JOIN t_package p_end ON
		o_end.package_id = p_end.package_id
	LEFT JOIN t_xref x
	ON
		x.client = c.ea_guid
		AND x.name = 'Stereotypes'
		AND x.type = 'connectorSrcEnd property'
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
)
WHERE
	(stereotypes IS NULL
		OR stereotypes NOT LIKE '%FQNAME%')
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_stereotypes`

 Shows all the stereotypes of the model elements. The stereotypes column contains all the stereotypes. For each of the stereotypes applied to a model element, a string like one of the following is present: @STEREO;Name=<stereo>;FQName=<profile_name>::<stereo>;@ENDSTEREO; (if the stereotype is defined in a UML profile, possibly as part of an MDG) or @STEREO;Name=<stereo>;GUID=<guid>;@ENDSTEREO; (if the stereotype is a custom stereotype, see https://sparxsystems.com/eahelp/creatingcustomstereotypes.html and see table t_stereotypes). 

```sql
SELECT
	p.ea_guid AS CLASSGUID,
	'Package' AS CLASSTYPE,
	NULL AS CLASSTABLE,
	p.name AS package_name,
	NULL AS classifier_name,
	NULL AS property_name,
	o.stereotype AS primary_unqualified_stereotype,
	x.description AS stereotypes
FROM
	(t_package p
INNER JOIN t_object o ON
	p.ea_guid = o.ea_guid)
LEFT JOIN t_xref x ON
	o.ea_guid = x.client
	AND x.name = 'Stereotypes'
WHERE
	p.package_id IN (#Branch#)
UNION ALL
SELECT
	o.ea_guid,
	o.object_type,
	NULL,
	p.name,
	o.name,
	NULL,
	o.stereotype,
	x.description
FROM
	(t_object o
INNER JOIN t_package p ON
	o.package_id = p.package_id)
LEFT JOIN t_xref x ON
	o.ea_guid = x.client
	AND x.name = 'Stereotypes'
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	a.ea_guid,
	'Attribute',
	NULL,
	p.name,
	o.name,
	a.name,
	a.stereotype,
	x.description
FROM
	((t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_package p ON
	o.package_id = p.package_id)
LEFT JOIN t_xref x ON
	a.ea_guid = x.client
	AND x.name = 'Stereotypes'
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_start.name,
	o_start.name,
	c.destrole,
	c.deststereotype,
	x.description
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_start ON
	o_start.package_id = p_start.package_id
LEFT JOIN t_xref x
	ON x.client = c.ea_guid
	AND x.name = 'Stereotypes'
	AND x.type = 'connectorDestEnd property'
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_end.name,
	o_end.name,
	c.sourcerole,
	c.sourcestereotype,
	x.description
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_end ON
	o_end.package_id = p_end.package_id
LEFT JOIN t_xref x
	ON x.client = c.ea_guid
	AND x.name = 'Stereotypes'
	AND x.type = 'connectorSrcEnd property'
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
ORDER BY
	package_name,
	classifier_name,
	property_name;

```

## `model_elements_tagged_value`

 Finds all packages, classifiers, properties, enumeration literals and associations (including aggregations) with the given tagged value. The actual value is only displayed for tagged values that are not of the memo type. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS name,
	pp.name AS namespace,
	op.value AS "<Search Term>"
FROM
	t_object o
INNER JOIN t_objectproperties op ON
	op.object_id = o.object_id
INNER JOIN t_package p ON
	p.ea_guid = o.ea_guid
INNER JOIN t_package pp ON
	p.parent_id = pp.package_id
WHERE
	p.package_id IN (#Branch#)
	AND o.object_type IN ('Package')
	AND op.property = ('<Search Term>')
UNION ALL
SELECT
	o.ea_guid,
	o.object_type,
	NULL,
	o.name,
	p.name,
	op.value
FROM
	t_object o
INNER JOIN t_objectproperties op ON
	op.object_id = o.object_id
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
	AND op.property = ('<Search Term>')
UNION ALL
SELECT
	a.ea_guid,
	'Attribute',
	NULL,
	a.name,
	o.name,
	at.value
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
INNER JOIN t_attributetag AT ON
	(a.id = at.elementid
		AND at.property = '<Search Term>')
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.destrole,
	o_start.name,
	tv.notes
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = '<Search Term>')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	c.sourcerole,
	o_end.name,
	tv.notes
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = '<Search Term>')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional')
UNION ALL
SELECT
	c.ea_guid,
	c.connector_type,
	't_connector',
	c.name,
	NULL,
	ct.value
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
INNER JOIN t_connectortag ct ON
	c.connector_id = ct.elementid)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND ct.property = ('<Search Term>')
ORDER BY
	name,
	namespace;

```

## `model_elements_tagged_value_export`

 Finds all classifiers, properties, enumeration literals and associations (including aggregations) with the given tagged value. The output of this query is the starting point for a CSV file to import with script import-data-model-custom-tags (EA Modelling Tools JavaScript): (1) use the "Copy Selected to Clipboard" functionality (see https://sparxsystems.com/eahelp/model_search_context_menu.html), (2) paste in LibreOffice Calc (use semicolon as separator, check "Trim spaces", keep the proposed character set, UTF-16), (3) modify the tagged values as needed and (4) save as a CSV file (use UTF-8 as character set, comma (,) as field delimiter and quotation mark (") as string delimiter). 

```sql
SELECT
	-- for display in EA
	o.ea_guid AS CLASSGUID,
	-- for import of tags via script import-data-model-custom-tags
	o.ea_guid AS GUID,
	-- for import of tags via script import-data-model-custom-tags
	o.name AS "UML-NAVN",
	-- for import of tags via script import-data-model-custom-tags
	p.name AS NAMESPACE,
	-- for display in EA
	o.object_type AS CLASSTYPE,
	-- for import of tags via script import-data-model-custom-tags
	CASE
		WHEN o.object_type = 'DataType' THEN 'DATA_TYPE'
		ELSE upper(o.object_type)
	END AS "TYPE",
	-- for display in EA
	NULL AS CLASSTABLE,
	-- for import of tags via script import-data-model-custom-tags
	(
	SELECT
		op.value
	FROM
		t_objectproperties op
	WHERE
		op.object_id = o.object_id
		AND op.property = ('<Search Term>')) AS "<Search Term>"
FROM
	t_object o
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	a.ea_guid,
	a.ea_guid,
	a.Name,
	o.Name,
	'Attribute',
	CASE
		WHEN a.styleex LIKE '%IsLiteral=1%' THEN 'ENUMERATION_LITERAL'
		ELSE 'ATTRIBUTE'
	END,
	NULL,
	(
	SELECT
		at.value
	FROM
		t_attributetag AT
	WHERE
		a.id = at.elementid
		AND at.property = ('<Search Term>'))
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
UNION ALL
SELECT
	c.ea_guid,
	-- substr is 1-based
	'{dst' || substr(c.ea_guid, 4),
	c.destrole,
	o_start.name,
	'AssociationEnd',
	'ASSOCIATION_END',
	't_connector',
	(
	SELECT
		tv.notes
	FROM
		t_taggedvalue tv
	WHERE
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = ('<Search Term>'))
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
UNION ALL
SELECT
	c.ea_guid,
	-- substr is 1-based
	'{src' || substr(c.ea_guid, 4),
	c.sourcerole,
	o_end.name,
	'AssociationEnd',
	'ASSOCIATION_END',
	't_connector',
	(
	SELECT
		tv.notes
	FROM
		t_taggedvalue tv
	WHERE
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = ('<Search Term>'))
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
UNION ALL
SELECT
	c.ea_guid,
	c.ea_guid,
	c.name,
	NULL,
	c.connector_type,
	'ASSOCIATION',
	't_connector',
	(
	SELECT
		ct.value
	FROM
		t_connectortag ct
	WHERE
		ct.elementid = c.connector_id
		AND ct.property = ('<Search Term>'))
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'));

```

## `model_missing_or_superfluous_usages`

 Returns the selected model, once per issue found, if any of the following is true: (1) it is not connected via a usage to all its model dependencies; (2) it is connected via a usage to a package that is not a model dependency. 

```sql
SELECT * FROM (
	WITH RECURSIVE conceptual_schema_or_standard(package_ea_guid, package_id, name, stereotype) AS (
	SELECT 
		p.ea_guid,
		p.package_id,
		p.name,
		o.stereotype
	FROM
		t_package p
	INNER JOIN t_object o ON
		p.ea_guid = o.ea_guid
	WHERE
		o.stereotype IN ('DKDomænemodel', 'AbstractSchema', 'ApplicationSchema')
		OR (
		 EXISTS (
			SELECT
				*
			FROM
				t_objectproperties op
			WHERE
				op.object_id = o.object_id
				AND lower(op.property) = 'isapplicationsschema'
				AND op.value = 'true')
		)
		OR (
			EXISTS (
				SELECT
					*
				FROM
					t_objectproperties op
				WHERE
					op.object_id = o.object_id
					AND op.property = 'name'
					AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'number'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'yearVersion'
						AND LENGTH(op.value) > 0)
			AND EXISTS (
					SELECT
						*
					FROM
						t_objectproperties op
					WHERE
						op.object_id = o.object_id
						AND op.property = 'publicationDate'
						AND LENGTH(op.value) > 0)
		)
	), attribute_type(type_id, type_name, type_package_id) AS (
		SELECT DISTINCT
			t.object_id,
			t.name,
			t.package_id
		FROM
			t_object o
		INNER JOIN t_attribute a ON
			o.object_id = a.object_id
		INNER JOIN t_object t ON
			a.classifier = t.object_id
		WHERE
			o.package_id IN (#Branch#)
			AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface')
			AND instr(a.styleex, 'IsLiteral=1') = 0
			AND t.package_id <> o.package_id
	), attribute_type_package_info(type_id, type_name, package_ea_guid, package_id, package_name, parent_id, level) AS (
		SELECT
			attribute_type.type_id,
			attribute_type.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			1
		FROM
			attribute_type
		INNER JOIN t_package p
			ON attribute_type.type_package_id = p.package_id
	UNION ALL
		SELECT
			atpi.type_id,
			atpi.type_name,
			p.ea_guid,
			p.package_id,
			p.name,
			p.parent_id,
			atpi.level * 2
		FROM
			attribute_type_package_info atpi
			INNER JOIN t_package p ON
				atpi.parent_id = p.package_id
		WHERE atpi.package_id NOT IN (SELECT package_id FROM conceptual_schema_or_standard)
	), attribute_type_conceptual_schema_or_standard_info(type_id, type_name, package_ea_guid, package_id, package_name) AS (
		SELECT
			type_id,
			type_name,
			package_ea_guid,
			package_id,
			package_name
		FROM
			attribute_type_package_info atpi
		WHERE level = (
				SELECT max(level)
				FROM attribute_type_package_info AS atpi2
				WHERE atpi2.type_id = atpi.type_id
			)
	), model_dependencies(package_ea_guid, package_id, package_name) AS (
	SELECT DISTINCT
		package_ea_guid,
		package_id,
		package_name
	FROM
		attribute_type_conceptual_schema_or_standard_info
	)
	SELECT
		p.ea_guid AS CLASSGUID,
		'Package' AS CLASSTYPE,
		p.name,
		#Concat 'The model is not connected via a usage to model dependency "', md.package_name, '"'# AS info
	FROM
		t_package p,
		model_dependencies md
	WHERE
		p.package_id = #Package#
		AND NOT EXISTS (
		SELECT
			*
		FROM
			t_connector c
		INNER JOIN t_object o ON
			(c.start_object_id = o.object_id
			AND c.direction = 'Source -> Destination')
			OR (c.end_object_id = o.object_id
			AND c.direction = 'Destination -> Source')
		INNER JOIN t_package p1 ON
			o.ea_guid = p1.ea_guid
		INNER JOIN t_object o2 ON
			(c.end_object_id = o2.object_id
			AND c.direction = 'Source -> Destination')
			OR (c.start_object_id = o2.object_id
			AND c.direction = 'Destination -> Source')
		WHERE
			c.connector_type = 'Usage'
			AND p1.package_id = #Package#
			AND o2.ea_guid = md.package_ea_guid
	)
	UNION ALL
	SELECT
		p.ea_guid,
		'Package',
		p.name,
		#Concat 'The model is connected via a usage to "', p2.name, '" but "', p2.name, '" is not a model dependency'#
	FROM
		t_package p,
		(t_connector c
	INNER JOIN t_object o ON
		(c.start_object_id = o.object_id
		AND c.direction = 'Source -> Destination')
		OR (c.end_object_id = o.object_id
		AND c.direction = 'Destination -> Source'))
	INNER JOIN t_package p1 ON
		o.ea_guid = p1.ea_guid
	INNER JOIN t_object o2 ON
		(c.end_object_id = o2.object_id
		AND c.direction = 'Source -> Destination')
		OR (c.start_object_id = o2.object_id
		AND c.direction = 'Destination -> Source')
	INNER JOIN t_package p2 ON
		o2.ea_guid = p2.ea_guid
	WHERE
		p.package_id = #Package#
		AND c.connector_type = 'Usage'
		AND p1.package_id = #Package#
		AND p2.ea_guid NOT IN (
			SELECT
				package_ea_guid
			FROM
				model_dependencies)
);

```

## `model_without_dependency_diagram`

 Returns the selected package if it does not contain a dependency diagram. 

```sql
SELECT
	p.ea_guid AS CLASSGUID,
	'Package' AS CLASSTYPE,
	p.name
FROM
	t_package p
WHERE
	p.package_id = #Package#
	AND NOT EXISTS (
	SELECT
		*
	FROM
		t_diagram d
	WHERE
		d.package_id = #Package#
		AND d.Diagram_Type = 'Package'
		AND d.name = #Concat '<Search Term> ',p.name#
	);

```

## `multivalued_attributes`

 Find all multivalued attributes, that is all attributes with a multiplicity with an upper bound greater than one. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS attribute_name,
	a.type AS type_name,
	a.classifier AS type_id,
	a.lowerbound,
	a.upperbound
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
WHERE
	o.package_id IN (#Branch#)
	AND a.upperbound NOT IN ('0', '1')
ORDER BY
	p.name,
	o.name,
	a.name;

```

## `navigable_association_ends_not_by_reference`

 Find the navigable association ends that don't have value inlineOrByReference set to byReference. Aggregations and compositions are not considered in this query. 

```sql
SELECT
	c.ea_guid AS CLASSGUID,
	'AssociationEnd' AS CLASSTYPE,
	't_connector' AS CLASSTABLE,
	o_start.name AS start_classifier_name,
	c.name AS association_name,
	c.destrole AS end_classifier_role,
	o_end.name AS end_classifier_name
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Association')
	OR (o_start.package_id IN (#Branch#)
		AND c.connector_type = 'Association'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional')
	AND (NOT EXISTS (
	SELECT
		*
	FROM
		t_taggedvalue tv
	WHERE
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'inlineOrByReference')
	OR (
	SELECT
		notes
	FROM
		t_taggedvalue tv
	WHERE
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'inlineOrByReference') <> 'byReference')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	o_end.name,
	c.name,
	c.sourcerole AS end_classifier_role,
	o_start.name
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Association')
	OR (o_start.package_id IN (#Branch#)
		AND c.connector_type = 'Association'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional')
	AND (NOT EXISTS (
	SELECT
		*
	FROM
		t_taggedvalue tv
	WHERE
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'inlineOrByReference')
	OR (
	SELECT
		notes
	FROM
		t_taggedvalue tv
	WHERE
		tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'inlineOrByReference') <> 'byReference');

```

## `navigable_association_ends_without_role_name`

 Find the navigable association ends that don't have a role name. 

```sql
SELECT
	c.ea_guid AS CLASSGUID,
	'AssociationEnd' AS CLASSTYPE,
	't_connector' AS CLASSTABLE,
	o_start.name AS start_classifier_name,
	c.name AS association_name,
	c.destrole AS end_classifier_role,
	o_end.name AS end_classifier_name
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
	AND c.destrole IS NULL
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	o_end.name,
	c.name,
	c.sourcerole AS end_classifier_role,
	o_start.name
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
	AND c.sourcerole IS NULL;

```

## `objects_language_not_none`

 Find the elements that are specified as being language-specific, that is, that have their language not set to "<none>" (see also https://sparxsystems.com/eahelp/generalproperties.html). Script set-language-none can be used to update these elements. Note: the default language can be configured in EA. It is a model-specific option, see https://sparxsystems.com/eahelp/code_generation_options.html. There is no user-specific option to set the default language. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	o.name,
	o.object_type,
	o.gentype
FROM
	t_object o
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Enumeration', 'Interface', 'Package')
	AND (o.gentype IS NULL
		OR o.gentype <> '<none>');

```

## `optional_properties`

 Find optional properties, that is properties that have a lower bound of 0. Properties that are actually conditional because of a constraint are also returned. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS classifier_name,
	a.name AS property,
	#Concat a.lowerbound, '..', a.upperbound # AS multiplicity
FROM
	t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id
WHERE
	o.package_id IN (#Branch#)
	AND a.lowerbound = '0'
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	o_start.name,
	c.destrole,
	c.destcard
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction = 'Source -> Destination'
	AND #Substring c.destcard,
	1,
	1# = '0'
UNION ALL
SELECT
	c.ea_guid AS CLASSGUID,
	'AssociationEnd' AS CLASSTYPE,
	't_connector',
	o_end.name,
	c.sourcerole,
	c.sourcecard
FROM
	(t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction = 'Destination -> Source'
	AND #Substring c.sourcecard,
	1,
	1# = '0'
ORDER BY
	classifier_name,
	property;

```

## `orphans`

 Find the objects that are not present on any diagram (in the selected package). 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	o.object_type,
	o.name,
	o.note AS notes,
	o.createddate,
	o.modifieddate
FROM
	t_object o
WHERE
	o.package_id IN (#Branch#)
	AND NOT EXISTS 
(
	SELECT
		*
	FROM
		t_diagramobjects
	INNER JOIN t_diagram ON
		t_diagramobjects.diagram_id = t_diagram.diagram_id
	WHERE
		t_diagram.package_id IN (#Branch#)
			AND t_diagramobjects.object_id = o.object_id);

```

## `packages_xsdinfo`

 Find the packages and the values of their tagged values xmlns, targetNamespace, version, xsdDocument, xsdEncodingRule. Note: these values can be set directly in a ShapeChange configuration file instead, via PackageInfo-elements and via the defaultEncodingRule parameter of the XML schema target. 

```sql
SELECT
	o.ea_guid AS CLASSGUID,
	o.object_type AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS name,
	pp.name AS namespace,
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'xmlns') AS "xmlns",
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'targetNamespace') AS "targetNamespace",
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'version') AS "version",
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'xsdDocument') AS "xsdDocument",
	(
	SELECT
			op.value
	FROM
			t_objectproperties op
	WHERE
			op.object_id = o.object_id
		AND op.property = 'xsdEncodingRule') AS "xsdEncodingRule"
FROM
	t_object o
INNER JOIN t_package p ON
	p.ea_guid = o.ea_guid
INNER JOIN t_package pp ON
	p.parent_id = pp.package_id
WHERE
	p.package_id IN (#Branch#)
	AND o.object_type IN ('Package')
ORDER BY
	pp.name,
	o.name;

```

## `profiles_in_model`

 Finds all profiles that are defined in the selected package. Profiles are defined in a tag with name "profiles" and a value consisting of a comma-separated profile names. 

```sql
SELECT
	*
FROM
	(
WITH RECURSIVE profiles_comma_separated(profiles) AS (
	SELECT
		DISTINCT op.value
	FROM
		t_objectproperties op
	INNER JOIN t_object o ON
		op.object_id = o.object_id
	INNER JOIN t_package p ON
		o.package_id = p.package_id
	WHERE
		o.package_id IN (#Branch#)
		AND op.property = 'profiles'
		AND op.value IS NOT NULL
UNION
	SELECT
		DISTINCT at.value
	FROM
		t_attributetag at
	INNER JOIN t_attribute a ON
		at.elementid = a.id
	INNER JOIN t_object o ON
		a.object_id = o.object_id
	WHERE
		o.package_id IN (#Branch#)
		AND at.property = 'profiles'
		AND at.value IS NOT NULL
UNION
	SELECT
		DISTINCT tv.notes
	FROM
		t_taggedvalue tv
	INNER JOIN t_connector c ON
		tv.elementid = c.ea_guid
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND tv.tagvalue = 'profiles'
		AND tv.notes IS NOT NULL
UNION
	SELECT
		DISTINCT tv.notes
	FROM
		t_taggedvalue tv
	INNER JOIN t_connector c ON
		tv.elementid = c.ea_guid
	INNER JOIN t_object o_start ON
		c.start_object_id = o_start.object_id
	INNER JOIN t_object o_end ON
		c.end_object_id = o_end.object_id
	WHERE
		((o_start.package_id IN (#Branch#)
			AND o_end.package_id IN (#Branch#)
				AND c.connector_type IN ('Association', 'Aggregation'))
			OR (o_start.package_id IN (#Branch#)
				AND (c.connector_type = 'Association'
					OR (c.connector_type = 'Aggregation'
						AND c.subtype = 'Weak')))
			OR (o_end.package_id IN (#Branch#)
				AND c.connector_type = 'Aggregation'
				AND c.subtype = 'Strong'))
		AND tv.tagvalue = 'profiles'
		AND tv.notes IS NOT NULL
),
	profiles_splitter(profile, remainder) AS (
	SELECT
		CASE
			WHEN INSTR(profiles, ',') = 0
		THEN profiles
			ELSE SUBSTR(profiles, 1, INSTR(profiles, ',') - 1)
		END AS part,
		CASE
			WHEN INSTR(profiles, ',') = 0
		THEN ''
			ELSE SUBSTR(profiles, INSTR(profiles, ',') - (-1))
		END AS remainder
	FROM
		profiles_comma_separated
UNION ALL
	SELECT
		CASE
			WHEN INSTR(remainder, ',') = 0
		THEN remainder
			ELSE SUBSTR(remainder, 1, INSTR(remainder, ',') - 1)
		END,
		CASE
			WHEN INSTR(remainder, ',') = 0
		THEN ''
			ELSE SUBSTR(remainder, INSTR(remainder, ',') - (-1))
		END
	FROM
		profiles_splitter
	WHERE
		remainder != ''
)
	SELECT
		DISTINCT profile
	FROM
		profiles_splitter
	ORDER BY
		1
);

```

## `properties_without_explicit_multiplicity`

 Find the properties of classifiers (not including non-navigable properties) that don't have a multiplicity specified explicitly. If it is not specified, it is assumed to be one, according to the UML specification. However, having a explicitly specified multiplicity is preferable. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	NULL AS CLASSTABLE,
	p.name AS package_name,
	o.name AS classifier_name,
	a.name AS property_name,
	a.type AS type,
	NULL AS association_name
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Interface')
	AND (a.lowerbound IS NULL OR a.upperbound IS NULL)
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_start.name,
	o_start.name,
	c.destrole,
	o_end.name,
	c.name
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_start ON
	o_start.package_id = p_start.package_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional'))
	AND c.destcard IS NULL
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	p_end.name,
	o_end.name,
	c.sourcerole,
	o_start.name,
	c.name
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
INNER JOIN t_package p_end ON
	o_end.package_id = p_end.package_id
WHERE
	(((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional'))
	AND c.sourcecard IS NULL;

```

## `scripts_and_scriptsgroups_with_scriptgroupname_like`

 Find the script groups that have a name like the given search term. Find also the scripts in those script groups. Use search term `eamt-%` to find the scripts and script groups from EA Modelling Tools JavaScript 

```sql
SELECT
	s.ScriptCategory,
	s.ScriptName,
	s.ScriptAuthor,
	s.Notes,
	s.Script
FROM
	t_script s
WHERE
	s.Script LIKE '<Search Term>'
	AND s.Notes LIKE '<Group%'
UNION ALL
SELECT
	s.ScriptCategory,
	s.ScriptName,
	s.ScriptAuthor,
	s.Notes,
	s.Script
FROM
	t_script s
INNER JOIN t_script s1 ON
	s1.ScriptName = s.ScriptAuthor
WHERE
	s1.script LIKE '<Search Term>'
	AND s1.Notes LIKE '<Group%'
ORDER BY
	ScriptCategory,
	ScriptName;

```

## `sequence_numbers_classifier`

 Find the sequence numbers (tagged value sequenceNumber) of all properties of the classifier selected in the project browser, ordered by (1) sequence number, (2) by ordering position (that is, if the sequence number is not available, and this information is only available for attributes) and (3) by property name. 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS classifier_name,
	a.name AS property,
	CAST(at.value AS INTEGER) AS sequenceNumber,
	a.pos AS ordering_position
FROM
	(t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
LEFT OUTER JOIN t_attributetag AT ON
	(a.id = at.elementid
		AND at.property = 'sequenceNumber')
WHERE
	o.object_id = #CurrentElementID#
UNION ALL
SELECT
	c.ea_guid AS CLASSGUID,
	'AssociationEnd' AS CLASSTYPE,
	't_connector' AS CLASSTABLE,
	o_start.name AS classifier_name,
	c.destrole AS property,
	CAST(tv.notes AS INTEGER) AS sequenceNumber,
	NULL
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
LEFT OUTER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'sequenceNumber')
WHERE
	o_start.object_id = #CurrentElementID#
	AND c.connector_type IN ('Association', 'Aggregation')
	AND c.direction IN ('Source -> Destination', 'Bi-Directional')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	o_end.name,
	c.sourcerole,
	CAST(tv.notes AS INTEGER),
	NULL
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
LEFT OUTER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'sequenceNumber')
WHERE
	o_end.object_id = #CurrentElementID#
	AND c.connector_type IN ('Association', 'Aggregation')
	AND c.direction IN ('Destination -> Source', 'Bi-Directional')
ORDER BY
	classifier_name,
	sequenceNumber,
	ordering_position,
	property;

```

## `sequence_numbers_package`

 Find the sequence numbers (tagged value sequenceNumber) of all properties of all classifiers in the package selected in the project browser, ordered (1) by classifier name, (2) by sequence number, (3) by ordering position (that is, if the sequence number is not available, and this information is only available for attributes) and (4) by property name 

```sql
SELECT
	a.ea_guid AS CLASSGUID,
	'Attribute' AS CLASSTYPE,
	NULL AS CLASSTABLE,
	o.name AS classifier_name,
	a.name AS property,
	CAST(at.value AS INTEGER) AS sequenceNumber,
	a.pos AS ordering_position
FROM
	((t_attribute a
INNER JOIN t_object o ON
	o.object_id = a.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id)
LEFT OUTER JOIN t_attributetag AT ON
	(a.id = at.elementid
		AND at.property = 'sequenceNumber')
WHERE
	o.package_id IN (#Branch#)
	AND o.object_type IN ('Class', 'DataType', 'Interface')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	o_start.name,
	c.destrole,
	CAST(tv.notes AS INTEGER),
	NULL
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
LEFT OUTER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_TARGET'
		AND tv.tagvalue = 'sequenceNumber')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Source -> Destination', 'Bi-Directional')
UNION ALL
SELECT
	c.ea_guid,
	'AssociationEnd',
	't_connector',
	o_end.name,
	c.sourcerole,
	CAST(tv.notes AS INTEGER),
	NULL
FROM
	((t_connector c
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id)
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id)
LEFT OUTER JOIN t_taggedvalue tv ON
	(tv.elementid = c.ea_guid
		AND tv.baseclass = 'ASSOCIATION_SOURCE'
		AND tv.tagvalue = 'sequenceNumber')
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
	AND c.direction IN ('Destination -> Source', 'Bi-Directional')
ORDER BY
	classifier_name,
	sequenceNumber,
	ordering_position,
	property;

```

## `tags_in_model`

 Finds all tags that are in use in the selected package. The tags on the package itself are taken into account as well. 

```sql
SELECT
	DISTINCT op.property AS tag
FROM
	t_objectproperties op
INNER JOIN t_object o ON
	op.object_id = o.object_id
INNER JOIN 
	t_package p
ON
	p.ea_guid = o.ea_guid
WHERE
	p.package_id IN (#Branch#)
UNION
SELECT
	DISTINCT op.property
FROM
	t_objectproperties op
INNER JOIN t_object o ON
	op.object_id = o.object_id
INNER JOIN t_package p ON
	o.package_id = p.package_id
WHERE
	o.package_id IN (#Branch#)
UNION
SELECT
	DISTINCT at.property
FROM
	t_attributetag at
INNER JOIN t_attribute a ON
	at.elementid = a.id
INNER JOIN t_object o ON
	a.object_id = o.object_id
WHERE
	o.package_id IN (#Branch#)
UNION	
SELECT
	DISTINCT tv.tagvalue
FROM
	t_taggedvalue tv
INNER JOIN t_connector c ON
	tv.elementid = c.ea_guid
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
UNION	
SELECT
	DISTINCT tv.tagvalue
FROM
	t_taggedvalue tv
INNER JOIN t_connector c ON
	tv.elementid = c.ea_guid
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
UNION
SELECT
	DISTINCT ct.property
FROM
	t_connectortag ct
INNER JOIN t_connector c ON
	ct.elementid = c.connector_id
INNER JOIN t_object o_start ON
	c.start_object_id = o_start.object_id
INNER JOIN t_object o_end ON
	c.end_object_id = o_end.object_id
WHERE
	((o_start.package_id IN (#Branch#)
		AND o_end.package_id IN (#Branch#)
			AND c.connector_type IN ('Association', 'Aggregation'))
		OR (o_start.package_id IN (#Branch#)
			AND (c.connector_type = 'Association'
				OR (c.connector_type = 'Aggregation'
					AND c.subtype = 'Weak')))
		OR (o_end.package_id IN (#Branch#)
			AND c.connector_type = 'Aggregation'
			AND c.subtype = 'Strong'))
ORDER BY
	1;

```

## `types_for_attributes`

 Gives all the types used for the attributes in the selected package and its subpackages. This query assumes that the attributes that have a type specified that is linked to an element (classifier) in the model, double-check with query attributes_with_type_without_classifier if needed. 

```sql
SELECT DISTINCT
	o2.ea_guid AS CLASSGUID,
	o2.object_type AS CLASSTYPE,
	o2.name AS type_name
FROM
	((t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_object o2 ON
	a.classifier = o2.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id
WHERE
	o.package_id IN (#Branch#)
ORDER BY
	o2.name;

```

## `types_for_attributes_external`

 Gives all the types that (1) are used for attributes and (2) that are not defined in the selected package or its subpackages. This query assumes that the attributes that have a type specified that is linked to an element (classifier) in the model, double-check with query attributes_with_type_without_classifier if needed. 

```sql
SELECT DISTINCT
	o2.ea_guid AS CLASSGUID,
	o2.object_type AS CLASSTYPE,
	o2.name AS type_name
FROM
	((t_attribute a
INNER JOIN t_object o ON
	a.object_id = o.object_id)
INNER JOIN t_object o2 ON
	a.classifier = o2.object_id)
INNER JOIN t_package p ON
	p.package_id = o.package_id
WHERE
	o.package_id IN (#Branch#)
	AND o2.package_id NOT IN (#Branch#)
ORDER BY
	o2.name;

```

