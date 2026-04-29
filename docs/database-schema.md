# Database schema

## Tables, primary keys and indexes

The relevant tables and indexes of the database schema of `.qea` files are documented below.

The table columns are here written using the case of the original schema.
However, the queries in this repository use lowercase column names.

```sql
CREATE TABLE t_attribute
(
	Object_ID INTEGER NULL,
	Name TEXT NULL,
	Scope TEXT NULL,
	Stereotype TEXT NULL,
	Containment TEXT NULL,
	IsStatic INTEGER NULL,
	IsCollection INTEGER NULL,
	IsOrdered INTEGER NULL,
	AllowDuplicates INTEGER NULL,
	LowerBound TEXT NULL,
	UpperBound TEXT NULL,
	Container TEXT NULL,
	Notes TEXT NULL,
	Derived TEXT NULL,
	ID INTEGER PRIMARY KEY,
	Pos INTEGER NULL,
	GenOption TEXT NULL,
	Length INTEGER NULL,
	Precision INTEGER NULL,
	Scale INTEGER NULL,
	Const INTEGER NULL,
	Style TEXT NULL,
	Classifier TEXT NULL,
	"Default" TEXT NULL,
	Type TEXT NULL,
	ea_guid TEXT NULL,
	StyleEx TEXT NULL
);

CREATE INDEX ix_attribute_classifier
 ON t_attribute (Classifier ASC);
CREATE INDEX ix_attribute_name
 ON t_attribute (Name ASC);
CREATE INDEX ix_attribute_objectid
 ON t_attribute (Object_ID ASC);
CREATE INDEX ix_attribute_type
 ON t_attribute (Type ASC);
CREATE UNIQUE INDEX uq_attribute_eaguid
 ON t_attribute (ea_guid ASC);

CREATE TABLE t_attributetag
(
	PropertyID INTEGER PRIMARY KEY,
	ElementID INTEGER NULL,
	Property TEXT NULL,
	VALUE TEXT NULL,
	NOTES TEXT NULL,
	ea_guid TEXT NULL
);

CREATE INDEX ix_attributetag_eaguid
 ON t_attributetag (ea_guid ASC);
CREATE INDEX ix_attributetag_elementid
 ON t_attributetag (ElementID ASC);
CREATE INDEX ix_attributetag_elementidprop
 ON t_attributetag (ElementID ASC,Property ASC);
CREATE INDEX ix_attributetag_property
 ON t_attributetag (Property ASC);
CREATE INDEX ix_attributetag_value
 ON t_attributetag (VALUE ASC);

CREATE TABLE t_connector
(
	Connector_ID INTEGER PRIMARY KEY,
	Name TEXT NULL,
	Direction TEXT NULL,
	Notes TEXT NULL,
	Connector_Type TEXT NULL,
	SubType TEXT NULL,
	SourceCard TEXT NULL,
	SourceAccess TEXT NULL,
	SourceElement TEXT NULL,
	DestCard TEXT NULL,
	DestAccess TEXT NULL,
	DestElement TEXT NULL,
	SourceRole TEXT NULL,
	SourceRoleType TEXT NULL,
	SourceRoleNote TEXT NULL,
	SourceContainment TEXT NULL,
	SourceIsAggregate INTEGER NULL,
	SourceIsOrdered INTEGER NULL,
	SourceQualifier TEXT NULL,
	DestRole TEXT NULL,
	DestRoleType TEXT NULL,
	DestRoleNote TEXT NULL,
	DestContainment TEXT NULL,
	DestIsAggregate INTEGER NULL,
	DestIsOrdered INTEGER NULL,
	DestQualifier TEXT NULL,
	Start_Object_ID INTEGER NULL,
	End_Object_ID INTEGER NULL,
	Top_Start_Label TEXT NULL,
	Top_Mid_Label TEXT NULL,
	Top_End_Label TEXT NULL,
	Btm_Start_Label TEXT NULL,
	Btm_Mid_Label TEXT NULL,
	Btm_End_Label TEXT NULL,
	Start_Edge INTEGER NULL,
	End_Edge INTEGER NULL,
	PtStartX INTEGER NULL,
	PtStartY INTEGER NULL,
	PtEndX INTEGER NULL,
	PtEndY INTEGER NULL,
	SeqNo INTEGER NULL,	
	HeadStyle INTEGER NULL,	
	LineStyle INTEGER NULL,	
	RouteStyle INTEGER NULL,	
	IsBold INTEGER NULL,	
	LineColor INTEGER NULL,	
	Stereotype TEXT NULL,
	VirtualInheritance TEXT NULL,
	LinkAccess TEXT NULL,
	PDATA1 TEXT NULL,
	PDATA2 TEXT NULL,
	PDATA3 TEXT NULL,
	PDATA4 TEXT NULL,
	PDATA5 TEXT NULL,
	DiagramID INTEGER NULL,
	ea_guid TEXT NULL,
	SourceConstraint TEXT NULL,
	DestConstraint TEXT NULL,
	SourceIsNavigable INTEGER NULL,
	DestIsNavigable INTEGER NULL,
	IsRoot INTEGER NULL,
	IsLeaf INTEGER NULL,
	IsSpec INTEGER NULL,
	SourceChangeable TEXT NULL,
	DestChangeable TEXT NULL,
	SourceTS TEXT NULL,
	DestTS TEXT NULL,
	StateFlags TEXT NULL,
	ActionFlags TEXT NULL,
	IsSignal INTEGER NULL,
	IsStimulus INTEGER NULL,
	DispatchAction TEXT NULL,
	Target2 INTEGER NULL,
	StyleEx TEXT NULL,
	SourceStereotype TEXT NULL,
	DestStereotype TEXT NULL,
	SourceStyle TEXT NULL,
	DestStyle TEXT NULL,
	EventFlags TEXT NULL
);

CREATE INDEX ix_connector_connectortype
 ON t_connector (Connector_Type ASC);
CREATE INDEX ix_connector_diagramid
 ON t_connector (DiagramID ASC);
CREATE INDEX ix_connector_endobjectid
 ON t_connector (End_Object_ID ASC);
CREATE INDEX ix_connector_endobjidconnid
 ON t_connector (End_Object_ID ASC,Connector_ID ASC);
CREATE INDEX ix_connector_pdata1
 ON t_connector (PDATA1 ASC);
CREATE INDEX ix_connector_pdata3
 ON t_connector (PDATA3 ASC);
CREATE INDEX ix_connector_pdata5
 ON t_connector (PDATA5 ASC);
CREATE INDEX ix_connector_seqno
 ON t_connector (SeqNo ASC);
CREATE INDEX ix_connector_startobjectid
 ON t_connector (Start_Object_ID ASC);
CREATE INDEX ix_connector_startobjidconnid
 ON t_connector (Start_Object_ID ASC,Connector_ID ASC);
CREATE INDEX ix_connector_subtype
 ON t_connector (SubType ASC);
CREATE UNIQUE INDEX uq_connector_eaguid
 ON t_connector (ea_guid ASC);

CREATE TABLE t_connectortag
(
	PropertyID INTEGER PRIMARY KEY,
	ElementID INTEGER NULL,
	Property TEXT NULL,
	VALUE TEXT NULL,
	NOTES TEXT NULL,
	ea_guid TEXT NULL
);

CREATE INDEX ix_connectortag_eaguid
 ON t_connectortag (ea_guid ASC);
CREATE INDEX ix_connectortag_elementid
 ON t_connectortag (ElementID ASC);
CREATE INDEX ix_connectortag_property
 ON t_connectortag (Property ASC);
CREATE INDEX ix_connectortag_value
 ON t_connectortag (VALUE ASC);

CREATE TABLE t_diagram
(
	Diagram_ID INTEGER PRIMARY KEY,
	Package_ID INTEGER NULL,	
	ParentID INTEGER NULL,
	Diagram_Type TEXT NULL,
	Name TEXT NULL,
	Version TEXT NULL,
	Author TEXT NULL,
	ShowDetails INTEGER NULL,
	Notes TEXT NULL,
	Stereotype TEXT NULL,
	AttPub INTEGER NOT NULL,
	AttPri INTEGER NOT NULL,
	AttPro INTEGER NOT NULL,
	Orientation TEXT NULL,
	cx INTEGER NULL,
	cy INTEGER NULL,
	Scale INTEGER NULL,
	CreatedDate TEXT NULL,
	ModifiedDate TEXT NULL,
	HTMLPath TEXT NULL,
	ShowForeign INTEGER NOT NULL,
	ShowBorder INTEGER NOT NULL,
	ShowPackageContents INTEGER NOT NULL,
	PDATA TEXT NULL,
	Locked INTEGER NOT NULL,
	ea_guid TEXT NULL,
	TPos INTEGER NULL,
	Swimlanes TEXT NULL,
	StyleEx TEXT NULL
);

CREATE INDEX ix_diagram_diagramtype
 ON t_diagram (Diagram_Type ASC);
CREATE INDEX ix_diagram_packageid
 ON t_diagram (Package_ID ASC);
CREATE INDEX ix_diagram_parentid
 ON t_diagram (ParentID ASC);
CREATE UNIQUE INDEX uq_diagram_eaguid
 ON t_diagram (ea_guid ASC);

CREATE TABLE t_diagramlinks
(
	DiagramID INTEGER NULL,
	ConnectorID INTEGER NULL,
	Geometry TEXT NULL,
	Style TEXT NULL,
	Hidden INTEGER NOT NULL,
	Path TEXT NULL,
	Instance_ID INTEGER PRIMARY KEY
);

CREATE INDEX ix_diagramlinks_connectorid
 ON t_diagramlinks (ConnectorID ASC);
CREATE INDEX ix_diagramlinks_diagramid
 ON t_diagramlinks (DiagramID ASC);

CREATE TABLE t_diagramobjects
(
	Diagram_ID INTEGER NULL,
	Object_ID INTEGER NULL,
	RectTop INTEGER NULL,
	RectLeft INTEGER NULL,
	RectRight INTEGER NULL,
	RectBottom INTEGER NULL,
	Sequence INTEGER NULL,
	ObjectStyle TEXT NULL,
	Instance_ID INTEGER PRIMARY KEY
);

CREATE INDEX ix_diagramobjects_diagramid
 ON t_diagramobjects (Diagram_ID ASC);
CREATE INDEX ix_diagramobjects_objectid
 ON t_diagramobjects (Object_ID ASC);
CREATE INDEX ix_diagramobjects_sequence
 ON t_diagramobjects (Sequence ASC);

CREATE TABLE t_object
(
	Object_ID INTEGER PRIMARY KEY,	
	Object_Type TEXT NULL,	
	Diagram_ID INTEGER NULL,	
	Name TEXT NULL,	
	Alias TEXT NULL,
	Author TEXT NULL,
	Version TEXT NULL,
	Note TEXT NULL,
	Package_ID INTEGER NULL,
	Stereotype TEXT NULL,
	NType INTEGER NULL,
	Complexity TEXT NULL,	
	Effort INTEGER NULL,	
	Style TEXT NULL,
	Backcolor INTEGER NULL,
	BorderStyle INTEGER NULL,	
	BorderWidth INTEGER NULL,
	Fontcolor INTEGER NULL,
	Bordercolor INTEGER NULL,
	CreatedDate TEXT NULL,
	ModifiedDate TEXT NULL,
	Status TEXT NULL,
	Abstract TEXT NULL,
	Tagged INTEGER NULL,
	PDATA1 TEXT NULL,
	PDATA2 TEXT NULL,
	PDATA3 TEXT NULL,
	PDATA4 TEXT NULL,
	PDATA5 TEXT NULL,
	Concurrency TEXT NULL,
	Visibility TEXT NULL,
	Persistence TEXT NULL,
	Cardinality TEXT NULL,
	GenType TEXT NULL,
	GenFile TEXT NULL,
	Header1 TEXT NULL,
	Header2 TEXT NULL,
	Phase TEXT NULL,
	Scope TEXT NULL,
	GenOption TEXT NULL,
	GenLinks TEXT NULL,
	Classifier INTEGER NULL,
	ea_guid TEXT NULL,
	ParentID INTEGER NULL,
	RunState TEXT NULL,
	Classifier_guid TEXT NULL,
	TPos INTEGER NULL,
	IsRoot INTEGER NULL,
	IsLeaf INTEGER NULL,
	IsSpec INTEGER NULL,
	IsActive INTEGER NULL,
	StateFlags TEXT NULL,
	PackageFlags TEXT NULL,
	Multiplicity TEXT NULL,
	StyleEx TEXT NULL,
	ActionFlags TEXT NULL,
	EventFlags TEXT NULL
);

CREATE INDEX ix_object_classifier
 ON t_object (Classifier ASC);
CREATE INDEX ix_object_classifierguid
 ON t_object (Classifier_guid ASC);
CREATE INDEX ix_object_eaguidclassifier
 ON t_object (ea_guid ASC,Classifier ASC);
CREATE INDEX ix_object_eventflags
 ON t_object (EventFlags ASC);
CREATE INDEX ix_object_name
 ON t_object (Name ASC);
CREATE INDEX ix_object_ntype
 ON t_object (NType ASC);
CREATE INDEX ix_object_objecttype
 ON t_object (Object_Type ASC);
CREATE INDEX ix_object_packageid
 ON t_object (Package_ID ASC);
CREATE INDEX ix_object_pdata1
 ON t_object (PDATA1 ASC);
CREATE INDEX ix_object_pdata2
 ON t_object (PDATA2 ASC);
CREATE INDEX ix_object_pdata3
 ON t_object (PDATA3 ASC);
CREATE INDEX ix_object_pdata4
 ON t_object (PDATA4 ASC);
CREATE INDEX ix_object_pdata5
 ON t_object (PDATA5 ASC);
CREATE INDEX ix_object_pkgidpdata1class
 ON t_object (Package_ID ASC,PDATA1 ASC,Classifier ASC);
CREATE UNIQUE INDEX uq_object_eaguid
 ON t_object (ea_guid ASC);

CREATE TABLE t_objectproperties
(
	PropertyID INTEGER PRIMARY KEY,
	Object_ID INTEGER NULL,
	Property TEXT NULL,
	Value TEXT NULL,
	Notes TEXT NULL,
	ea_guid TEXT NULL
);

CREATE INDEX ix_objectproperties_eaguid
 ON t_objectproperties (ea_guid ASC);
CREATE INDEX ix_objectproperties_objectid
 ON t_objectproperties (Object_ID ASC);
CREATE INDEX ix_objectproperties_objidprop
 ON t_objectproperties (Object_ID ASC,Property ASC);
CREATE INDEX ix_objectproperties_property
 ON t_objectproperties (Property ASC);
CREATE INDEX ix_objectproperties_value
 ON t_objectproperties (Value ASC);

CREATE TABLE t_package
(
	Package_ID INTEGER PRIMARY KEY,
	Name TEXT NULL,
	Parent_ID INTEGER NULL,
	CreatedDate TEXT NULL,
	ModifiedDate TEXT NULL,
	Notes TEXT NULL,
	ea_guid TEXT NULL,
	XMLPath TEXT NULL,
	IsControlled INTEGER NULL,
	LastLoadDate TEXT NULL,
	LastSaveDate TEXT NULL,
	Version TEXT NULL,
	Protected INTEGER NULL,
	PkgOwner TEXT NULL,
	UMLVersion TEXT NULL,
	UseDTD INTEGER NULL,
	LogXML INTEGER NULL,
	CodePath TEXT NULL,
	Namespace TEXT NULL,
	TPos INTEGER NULL,
	PackageFlags TEXT NULL,
	BatchSave INTEGER NULL,
	BatchLoad INTEGER NULL
);

CREATE INDEX ix_package_name
 ON t_package (Name ASC);
CREATE INDEX ix_package_packageid
 ON t_package (Package_ID ASC);
CREATE INDEX ix_package_parentid
 ON t_package (Parent_ID ASC);
CREATE UNIQUE INDEX uq_package_eaguid
 ON t_package (ea_guid ASC);

CREATE TABLE t_taggedvalue
(
	PropertyID TEXT PRIMARY KEY,
	ElementID TEXT NULL,
	BaseClass TEXT NULL,
	TagValue TEXT NULL,
	Notes TEXT NULL
);

CREATE INDEX ix_taggedvalue_elementid
 ON t_taggedvalue (ElementID ASC);

CREATE TABLE t_xref
(
	XrefID TEXT PRIMARY KEY,
	Name TEXT NULL,
	Type TEXT NULL,
	Visibility TEXT NULL,
	Namespace TEXT NULL,
	Requirement TEXT NULL,
	"Constraint" TEXT NULL,
	Behavior TEXT NULL,
	"Partition" TEXT NULL,
	Description TEXT NULL,
	Client TEXT NULL,
	Supplier TEXT NULL,
	Link TEXT NULL
);

CREATE INDEX ix_xref_client
 ON t_xref (Client ASC);
CREATE INDEX ix_xref_name
 ON t_xref (Name ASC);
CREATE INDEX ix_xref_nametype
 ON t_xref (Name ASC,Type ASC);
CREATE INDEX ix_xref_supplier
 ON t_xref (Supplier ASC);
CREATE INDEX ix_xref_type
 ON t_xref (Type ASC);
CREATE INDEX "ix_xref_clientname"
 ON "t_xref" ("Client" ASC,"Name" ASC);
```

## Foreign keys

No foreign keys are defined. However, for the development of new queries, the following foreign keys are assumed to be present:

```sql
ALTER TABLE t_attribute ADD FOREIGN KEY (Object_ID) REFERENCES t_object (Object_ID);

ALTER TABLE t_attribute ADD FOREIGN KEY (Classifier) REFERENCES t_object (Object_ID);

ALTER TABLE t_objectproperties ADD FOREIGN KEY (Object_ID) REFERENCES t_object (Object_ID);

ALTER TABLE t_connector ADD FOREIGN KEY (Start_Object_ID) REFERENCES t_object (Object_ID);

ALTER TABLE t_connector ADD FOREIGN KEY (End_Object_ID) REFERENCES t_object (Object_ID);

ALTER TABLE t_objectconstraint ADD FOREIGN KEY (Object_ID) REFERENCES t_object (Object_ID);

ALTER TABLE t_diagramobjects ADD FOREIGN KEY (Object_ID) REFERENCES t_object (Object_ID);

ALTER TABLE t_object ADD FOREIGN KEY (Package_ID) REFERENCES t_package (Package_ID);

ALTER TABLE t_diagram ADD FOREIGN KEY (Package_ID) REFERENCES t_package (Package_ID);

ALTER TABLE t_package ADD FOREIGN KEY (Parent_ID) REFERENCES t_package (Package_ID);

ALTER TABLE t_attributetag ADD FOREIGN KEY (ElementID) REFERENCES t_attribute (ID);

ALTER TABLE t_connectortag ADD FOREIGN KEY (ElementID) REFERENCES t_connector (Connector_ID);

ALTER TABLE t_diagramlinks ADD FOREIGN KEY (ConnectorID) REFERENCES t_connector (Connector_ID);

ALTER TABLE t_xref ADD FOREIGN KEY (Client) REFERENCES t_connector (ea_guid);

ALTER TABLE t_taggedvalue ADD FOREIGN KEY (ElementID) REFERENCES t_connector (ea_guid);

ALTER TABLE t_diagramobjects ADD FOREIGN KEY (Diagram_ID) REFERENCES t_diagram (Diagram_ID);

ALTER TABLE t_diagramlinks ADD FOREIGN KEY (DiagramID) REFERENCES t_diagram (Diagram_ID);
```

## Worth knowing

An entry in `t_package` has a corresponding entry in `t_object`, with `o.object_type = 'Package'` and 
`t_object.ea_guid = t_package.ea_guid`. This is undocumented behaviour.

Tagged values can be of the memo type. See the existing queries for how to handle these.
Note that the pattern for tagged values for association ends is different than for tagged values of object and attributes.

<!-- TODO document tagged values better -->

<!-- TODO document the WHERE statements for relation (ends) -->
