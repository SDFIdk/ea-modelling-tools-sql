<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:x="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="x">
    
    <!-- Create HTML documentation for the searches -->

    <xsl:output
        method="xhtml"
        html-version="5.0"
        include-content-type="yes"
        omit-xml-declaration="yes"
        indent="yes" />
    
    <!-- Define a parameter for the folder path -->
    <xsl:param name="folderPath" />

    <xsl:param name="mdgFileName" />

    <xsl:param name="searchesFileName" />

    <xsl:variable
        name="title"
        select="'EA Modelling Tools SQL'" />
        
    <!-- A hack to be able to add a comment to a SQL query in EA is to enclose the comment with
    #DB=COMMENT# (but not on the first line of the query!). -->
    <xsl:variable
        name="commentDelimiter"
        select="'#DB=COMMENT#'" />

    <!-- JavaScript library hightlight.js is used for highlighting the SQL syntax, see https://highlightjs.org/. -->
    <xsl:variable
        name="highlightjsLocation"
        select="'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/'" />

    <xsl:variable
        name="highlightjsVersion"
        select="'11.7.0'" />

    <xsl:variable
        name="highlightjsStyle"
        select="'idea'" />

    <!-- Start template: read a set of files containing EA searches -->
    <xsl:template name="start-template">
        <html
            xmlns="http://www.w3.org/1999/xhtml"
            lang="en">
            <head>
                <title>
                    <xsl:value-of select="$title" />
                </title>
                <style>html{font-family: sans-serif;}pre{width: max-content;}</style>
                <link rel="stylesheet">
                    <xsl:attribute name="href">
                        <xsl:value-of select="concat($highlightjsLocation, $highlightjsVersion, '/styles/', $highlightjsStyle, '.min.css')" />
                    </xsl:attribute>
                </link>
                <script>
                    <xsl:attribute name="src">
                        <xsl:value-of select="concat($highlightjsLocation, $highlightjsVersion, '/highlight.min.js')" />
                    </xsl:attribute>
                </script>
                <script>
                    <xsl:attribute name="src">
                        <xsl:value-of select="concat($highlightjsLocation, $highlightjsVersion, '/languages/sql.min.js')" />
                    </xsl:attribute>
                </script>
                <script>hljs.highlightAll();</script>
            </head>
            <body>
                <h1>
                    <xsl:value-of select="$title" />
                </h1>
                <h2>Introduction</h2>
                <p>
                    This page gives an overview of all the model searches defined in
                    <xsl:value-of select="$title" />
                    . They can be downloaded for import as
                    <ul>
                        <li>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="concat('./', $mdgFileName)" />
                                </xsl:attribute>
                                non-editable model searches, that will be contained in the
                                <xsl:value-of select="$title" />
                                group
                            </a>
                        </li>
                        <li>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="concat('./', $searchesFileName)" />
                                </xsl:attribute>
                                editable model searches, that will be contained in the My Searches group
                            </a>
                        </li>
                    </ul>
                </p>
                <h2>Model searches</h2>
                <xsl:variable
                    name="collectionUri"
                    select="concat('file:///', replace($folderPath, '\\', '/'), '?select=*.xml')" />
                <xsl:apply-templates select="collection($collectionUri)/RootSearch/Search">
                    <xsl:sort select="@Name" />
                </xsl:apply-templates>
            </body>
        </html>
    </xsl:template>

    <!-- Extract the comment on the SQL query and the SQL query itself. -->
    <xsl:template match="Search">
        <h3>
            <xsl:value-of select="@Name" />
        </h3>
        <xsl:variable
            name="savedSqlQuery"
            select="SrchOn/RootTable/@Filter" />
        <p>
            <xsl:if test="contains($savedSqlQuery, $commentDelimiter)">
                <xsl:value-of select="substring-before(substring-after($savedSqlQuery, $commentDelimiter), $commentDelimiter)" />
            </xsl:if>
        </p>
        <pre>
            <code class="language-sql">
                <xsl:choose>
                    <xsl:when test="contains($savedSqlQuery, $commentDelimiter)">
                        <xsl:value-of select="substring-before($savedSqlQuery, $commentDelimiter)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$savedSqlQuery" />
                    </xsl:otherwise>
                </xsl:choose>
            </code>
        </pre>
    </xsl:template>
</xsl:stylesheet>