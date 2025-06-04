<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:x="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="x">
    
    <!-- Create HTML documentation for the searches -->

    <!-- Set output method to html and not to xhtml,
    as the scripts from designsystem.js possibly not always generate XHTML (e.g. use of br-tag). -->
    <xsl:output
        method="html"
        html-version="5.0"
        include-content-type="no"
        omit-xml-declaration="yes"
        indent="yes" />

    <xsl:param name="mdgFileName" />

    <xsl:param name="searchesFileName" />

    <xsl:param name="viewsFileName" />
    
    <xsl:variable
        name="creator"
        select="'Agency for Climate Data'" />

    <xsl:variable
        name="title"
        select="/MDG.Technology/Documentation/@name" />
        
    <!-- A hack to be able to add a comment to a SQL query in EA is to enclose the comment with
    #DB=COMMENT# (but not on the first line of the query!). -->
    <xsl:variable
        name="commentDelimiter"
        select="'#DB=COMMENT#'" />
        
    <xsl:variable
        name="designsystemVersion"
        select="'8'" />

    <xsl:variable
        name="designsystemUrl"
        select="'https://cdn.dataforsyningen.dk/assets/designsystem/v' || $designsystemVersion" />
        
    <xsl:variable
        name="exitSiteIcon"
        select="document($designsystemUrl || '/icons/exitsite.svg')" />

    <!-- JavaScript library hightlight.js is used for highlighting the SQL syntax, see https://highlightjs.org/. -->
    <xsl:variable
        name="highlightjsLocation"
        select="'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/'" />

    <xsl:variable
        name="highlightjsVersion"
        select="'11.11.1'" />

    <xsl:variable
        name="highlightjsStyle"
        select="'idea'" />

    <!-- Start template. -->
    <xsl:template name="start-template">
        <xsl:document>
            <html lang="en">
                <head>
                    <title>
                        <xsl:value-of select="$title" />
                    </title>
                    <meta charset="utf-8" />
                    <meta
                        name="viewport"
                        content="width=device-width, initial-scale=1.0" />
                    <link rel="stylesheet">
                        <xsl:attribute
                            name="href"
                            select="$designsystemUrl || '/designsystem.css'" />
                    </link>
                    <style>
                        .grid-container{
                            display: grid;
                            gap: var(--gap);
                            grid-template-columns: 1fr;
                            height: auto;
                            
                            @media (min-width: 55rem) {
                                grid-template-columns: 2fr 5fr;
                                height: 100vh;
                            }
                        }
                        #toc {
                            grid-row: 1;
                            grid-column: 1;
                        }
                        #text {
                            grid-row: 2;
                            grid-column: 1;
                            @media (min-width: 55rem) {
                                grid-row: 1;
                                grid-column: 2;
                            }
                        }
                        .grid-container>div{
                            overflow-y: auto;
                            @media (min-width: 55rem) {
                                overflow-y: scroll;
                            }
                        }
                        #toc>nav.ds-nav-vertical {
                            margin-top: var(--space-md);
                            text-wrap: wrap;
                            word-break: break-all;
                        }
                        #toc>nav.ds-nav-vertical > *{
                            border: none
                        }
                        #toc>nav.ds-nav-vertical a{
                            padding: var(--space-sm)
                        }
                        section {
                            margin-bottom: var(--space-lg);
                        }
                        pre>code.hljs {
                            background-color: var(--code-background-color);
                        }
                    </style>
                    <script type="module">
                        import {
                            DSLogo,
                            DSLogoTitle
                        } from
                        <xsl:value-of select="' '' ' || $designsystemUrl || '/designsystem.js '' '" />
                        customElements.define('ds-logo', DSLogo)
                        customElements.define('ds-logo-title', DSLogoTitle)
                    </script>
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
                    <header
                        id="header"
                        class="ds-header">
                        <div class="ds-container">
                            <ds-logo-title>
                                <xsl:attribute name="byline" select="$creator" />
                                <xsl:attribute name="title" select="$title" />
                            </ds-logo-title>
                            <h1>
                                <xsl:value-of select="$title" />
                            </h1>
                            <p class="manchet">
                                <xsl:value-of select="'Version ' || /MDG.Technology/Documentation/@version" />
                            </p>
                        </div>
                    </header>
                    <div class="grid-container">
                        <div
                            id="toc"
                            class="ds-padding">
                            <nav class="ds-nav-vertical">
                                <h2>Model searches overview</h2>
                                <ol>
                                    <xsl:apply-templates
                                        select="/MDG.Technology/ModelSearches/Search"
                                        mode="overview">
                                        <xsl:sort select="@Name" />
                                    </xsl:apply-templates>
                                </ol>
                            </nav>
                        </div>
                        <div id="text">
                            <main>
                                <div class="ds-container">
                                    <section>
                                        <h2>Introduction</h2>
                                        <p>
                                            <xsl:text>This page gives an overview of all the model searches and model views defined in </xsl:text>
                                            <a
                                                href="https://sparxsystems.com/eahelp/search_view.html"
                                                target="_blank"
                                                rel="noreferrer noopener">
                                                model searches
                                                <xsl:copy-of select="$exitSiteIcon" />
                                            </a>
                                            <xsl:text> and </xsl:text>
                                            <a
                                                href="https://sparxsystems.com/eahelp/model_views.html"
                                                target="_blank"
                                                rel="noreferrer noopener">
                                                model views
                                                <xsl:copy-of select="$exitSiteIcon" />
                                            </a>
                                            <xsl:text> defined in </xsl:text>
                                            <xsl:value-of select="$title" />
                                            <xsl:text>. They can be downloaded for import as</xsl:text>
                                            <ul>
                                                <li>
                                                    <a>
                                                        <xsl:attribute name="href">
                                                            <xsl:value-of select="concat('./', $mdgFileName)" />
                                                        </xsl:attribute>
                                                        <xsl:text>non-editable model searches and model views, as part of an MDG</xsl:text>
                                                    </a>
                                                    <xsl:text> (available in the "</xsl:text>
                                                    <xsl:value-of select="$title" />
                                                    <xsl:text>" search category in the Find in Project window and in the "</xsl:text>
                                                    <xsl:value-of select="$title" />
                                                    <xsl:text> Views" root node in the Model Views window, respectively)</xsl:text>
                                                </li>
                                                <li>
                                                    <a>
                                                        <xsl:attribute name="href">
                                                            <xsl:value-of select="concat('./', $searchesFileName)" />
                                                        </xsl:attribute>
                                                        <xsl:text>editable model searches</xsl:text>
                                                    </a>
                                                    <xsl:text> (available in the "My Searches" search category in the Find in Project window)</xsl:text>
                                                </li>
                                                <li>
                                                    <a>
                                                        <xsl:attribute name="href">
                                                            <xsl:value-of select="concat('./', $viewsFileName)" />
                                                        </xsl:attribute>
                                                        <xsl:text>editable model views</xsl:text>
                                                    </a>
                                                    <xsl:text> (available in the root node "</xsl:text>
                                                    <xsl:value-of select="$title" />
                                                    <xsl:text>" in the Model Views window)</xsl:text>
                                                </li>
                                            </ul>
                                        </p>
                                    </section>
                                    <section>
                                        <h2>Model views</h2>
                                        <xsl:apply-templates select="/MDG.Technology/ModelViews/RootView/Category" />
                                    </section>
                                    <section>
                                        <h2>Model searches details</h2>
                                        <xsl:apply-templates
                                            select="/MDG.Technology/ModelSearches/Search"
                                            mode="details">
                                            <xsl:sort select="@Name" />
                                        </xsl:apply-templates>
                                    </section>
                                </div>
                            </main>
                        </div>
                    </div>
                </body>
            </html>
        </xsl:document>
    </xsl:template>
    
    <!-- Extract the model view categories. -->
    <xsl:template match="Category">
        <section>
            <h3>
                <xsl:attribute name="id">
                    <xsl:value-of select="concat('id_', substring(@ID, 2, 36))" />
                </xsl:attribute>
                <xsl:value-of select="@Name" />
            </h3>
            <table>
                <thead>
                    <tr>
                        <th>Description</th>
                        <th>Search</th>
                        <th>Search term</th>
                    </tr>
                </thead>
                <tbody>
                    <xsl:apply-templates select="Search" />
                </tbody>
            </table>
        </section>
    </xsl:template>

    <!-- Create a table showing the searches contained in a category. -->
    <xsl:template match="Category/Search">
        <xsl:variable
            name="searchId"
            select="@SrchID" />
        <tr>
            <td>
                <xsl:value-of select="@Name" />
            </td>
            <td>
                <xsl:choose>
                    <xsl:when test="exists(/MDG.Technology/ModelSearches/Search[@GUID=$searchId])">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:value-of select="concat('#', 'id_', substring($searchId, 2, 36))" />
                            </xsl:attribute>
                            <xsl:variable
                                name="info"
                                select="concat('See search ', /MDG.Technology/ModelSearches/Search[@GUID=$searchId]/@Name)" />
                            <xsl:attribute name="aria-label">
                                <xsl:value-of select="$info" />
                            </xsl:attribute>
                            <xsl:attribute name="title">
                             <xsl:value-of select="$info" />
                            </xsl:attribute>
                            <xsl:value-of select="'see search details'" />
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>ERROR The model search used by model view "</xsl:text>
                            <xsl:value-of select="@Name" />
                            <xsl:text>" is not present in </xsl:text>
                            <xsl:value-of select="$mdgFileName" />
                            <xsl:text> (search id=</xsl:text>
                            <xsl:value-of select="$searchId" />
                            <xsl:text>). Add that model search to the repository and build again.</xsl:text>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </td>
            <td>
                <xsl:value-of select="@SrchTerm" />
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template
        match="ModelSearches/Search"
        mode="overview">
        <li>
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="concat('#', 'id_', substring(@GUID, 2, 36))" />
                </xsl:attribute>
                <xsl:value-of select="@Name" />
            </a>
        </li>
    </xsl:template>

    <!-- Extract the comment on the SQL query and the SQL query itself. -->
    <xsl:template
        match="ModelSearches/Search"
        mode="details">
        <section>
            <h3>
                <xsl:attribute name="id">
                    <xsl:value-of select="concat('id_', substring(@GUID, 2, 36))" />
                </xsl:attribute>
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
            <pre data-theme="light">
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
        </section>
    </xsl:template>
</xsl:stylesheet>