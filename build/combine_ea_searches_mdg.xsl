<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <!-- Combine files containing EA searches exported from EA into an MDG
    (containing only searches) -->

    <xsl:output
        method="xml"
        indent="yes" />
    
    <!-- Define a parameter for the folder path -->
    <xsl:param name="folderPath" />

    <xsl:param name="version" />

    <!-- Start template: read a set of files containing EA searches -->
    <xsl:template name="start-template">
        <MDG.Technology version="1.0">
            <Documentation
                id="eamt-sql"
                name="EA Modelling Tools SQL"
                notes="Model Searches that can be used as a supplement to the other EA Modelling Tools">
                <xsl:attribute name="version">
                    <xsl:value-of select="$version" />
                </xsl:attribute>
            </Documentation>
            <ModelSearches>
                <xsl:variable
                    name="collectionUri"
                    select="concat('file:///', replace($folderPath, '\\', '/'), '?select=*.xml')" />
                <xsl:message>
                    Collection URI:
                    <xsl:value-of select="$collectionUri" />
                </xsl:message>
                <xsl:apply-templates select="collection($collectionUri)/RootSearch/Search">
                    <xsl:sort select="@Name" />
                </xsl:apply-templates>
            </ModelSearches>
        </MDG.Technology>
    </xsl:template>
    
	<!-- Identity transformation -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>