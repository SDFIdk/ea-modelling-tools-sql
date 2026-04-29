<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:x="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="x">
    
    <!-- Create Markdown documentation for the searches, for development purposes
    (the HTML documentation does not link to it). -->

    <xsl:output
        method="text"
        encoding="UTF-8" />

    <!-- A hack to be able to add a comment to a SQL query in EA is to enclose the comment with
    #DB=COMMENT# (but not on the first line of the query!). -->
    <xsl:variable
        name="commentDelimiter"
        select="'#DB=COMMENT#'" />

    <!-- Start template. -->
    <xsl:template name="start-template">
        <xsl:value-of select="'# ' || /MDG.Technology/Documentation/@name || '&#13;&#10;'" />
        <xsl:text>&#13;&#10;</xsl:text>
        <xsl:apply-templates select="/MDG.Technology/ModelSearches/Search">
            <xsl:sort select="@Name" />
        </xsl:apply-templates>
    </xsl:template>

    <!-- Extract the comment on the SQL query and the SQL query itself. -->
    <xsl:template match="ModelSearches/Search">
        <xsl:value-of select="'## `' || @Name || '`&#13;&#10;'" />
        <xsl:text>&#13;&#10;</xsl:text>
        <xsl:variable
            name="savedSqlQuery"
            select="SrchOn/RootTable/@Filter" />
        <xsl:if test="contains($savedSqlQuery, $commentDelimiter)">
            <xsl:value-of select="substring-before(substring-after($savedSqlQuery, $commentDelimiter), $commentDelimiter) || '&#13;&#10;'" />
            <xsl:text>&#13;&#10;</xsl:text>
        </xsl:if>
        <xsl:value-of select="'```sql&#13;&#10;'" />
        <xsl:choose>
            <xsl:when test="contains($savedSqlQuery, $commentDelimiter)">
                <xsl:value-of select="substring-before($savedSqlQuery, $commentDelimiter)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$savedSqlQuery" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#13;&#10;</xsl:text>
        <xsl:value-of select="'```&#13;&#10;'" />
        <xsl:text>&#13;&#10;</xsl:text>
    </xsl:template>
</xsl:stylesheet>