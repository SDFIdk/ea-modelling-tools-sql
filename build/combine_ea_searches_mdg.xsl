<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <!-- Combine files containing EA searches exported from EA into an MDG
    (containing only searches) -->

    <xsl:output indent="yes" />
    
    <!-- Identity transformation -->
    <xsl:mode on-no-match="shallow-copy" />
    
    <!-- Define a parameter for the folder path -->
    <xsl:param name="folderPath" />

    <!-- Define a parameter for the version of the MDG -->
    <xsl:param name="version" />

    <!-- Start template: read a set of files containing EA searches -->
    <xsl:template name="start-template">
    
        <!-- Construct the URI that identifies the file that contains the model views -->
        <xsl:variable
            name="modelViewsDocumentUri"
            select="concat('file:///', replace($folderPath, '\\', '/'), '/modelviews/modelviews.xml')" />
            
        <!-- Construct the URI that identifies all the files that contain searches -->
        <xsl:variable
            name="searchCollectionUri"
            select="concat('file:///', replace($folderPath, '\\', '/'), '/modelsearches?select=*.xml')" />
    
        <xsl:document>
            <MDG.Technology version="1.0">
                <Documentation
                    id="eamt-sql"
                    name="EA Modelling Tools SQL"
                    notes="Model Searches and Model Views that can be used as a supplement to the other EA Modelling Tools">
                    <xsl:attribute name="version">
                        <xsl:value-of select="$version" />
                    </xsl:attribute>
                </Documentation>
                <ModelViews>
                    <xsl:apply-templates select="doc($modelViewsDocumentUri)/Views/RootView" />
                </ModelViews>
                <ModelSearches>
                    <xsl:apply-templates select="collection($searchCollectionUri)/RootSearch/Search">
                        <xsl:sort select="@Name" />
                    </xsl:apply-templates>
                </ModelSearches>
            </MDG.Technology>
        </xsl:document>
        
    </xsl:template>

</xsl:stylesheet>