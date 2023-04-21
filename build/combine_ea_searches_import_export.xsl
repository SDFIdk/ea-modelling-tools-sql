<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <!-- Combine files containing EA searches exported from EA into one document, 
    following the same structure as in searches exported from EA and as in
    C:\Users\<username>\AppData\Roaming\Sparx Systems\EA\Search Data\EA_Search.xml -->
    
    <xsl:output method="xml" indent="yes" />
    
    <!-- Define a parameter for the folder path -->
    <xsl:param name="folderPath" />

    <!-- Start template: read a set of files containing EA searches -->
    <xsl:template name="start-template">
        <RootSearch>
            <xsl:variable
                name="collectionUri"
                select="concat('file:///', replace($folderPath, '\\', '/'), '?select=*.xml')" />
            <xsl:apply-templates select="collection($collectionUri)/RootSearch/Search">
                <xsl:sort select="@Name"/>
            </xsl:apply-templates>
        </RootSearch>
    </xsl:template>
    
	<!-- Identity transformation -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>