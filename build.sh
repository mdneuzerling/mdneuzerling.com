#!/usr/bin/env bash
set -uo pipefail
# Note: Not using -e as grep returns 1 when no match is found, which would exit the script

# Enable nullglob to handle empty globs gracefully
shopt -s nullglob

# =============================================================================
# Static Blog Generator
# Dependencies: bash, pandoc, sed, awk, grep
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.toml"
CONTENT_DIR="$SCRIPT_DIR/content/post"
STATIC_DIR="$SCRIPT_DIR/static"
DIST_DIR="$SCRIPT_DIR/dist"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# Safety check: Verify we're in the expected directory structure
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.toml not found. Are you running this script from the correct directory?" >&2
    exit 1
fi

# =============================================================================
# Configuration Parser
# =============================================================================

parse_config() {
    local key="$1"
    grep "^${key} = " "$CONFIG_FILE" | sed 's/^[^=]*= *//' | sed 's/^"//;s/"$//'
}

parse_config_array() {
    local key="$1"
    local in_array=0
    local result=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^${key}[[:space:]]*=[[:space:]]*\[ ]]; then
            in_array=1
            continue
        fi
        if [[ $in_array -eq 1 ]]; then
            if [[ "$line" =~ ^\] ]]; then
                break
            fi
            local item=$(echo "$line" | sed 's/^[[:space:]]*"//;s/"[,]*$//')
            if [[ -n "$item" ]]; then
                result="${result}${item}"$'\n'
            fi
        fi
    done < "$CONFIG_FILE"
    echo -n "$result"
}

# Load configuration
SITE_TITLE=$(parse_config "site_title")
SITE_DESCRIPTION=$(parse_config "site_description")
BASE_URL=$(parse_config "base_url")
AUTHOR_NAME=$(parse_config "author_name")
AUTHOR_DESCRIPTION=$(parse_config "author_description")
PROFILE_IMAGE=$(parse_config "profile_image")
GITHUB_URL=$(parse_config "github_url")
LINKEDIN_URL=$(parse_config "linkedin_url")
BLUESKY_URL=$(parse_config "bluesky_url")
POSTS_PER_PAGE=$(parse_config "posts_per_page")
EXCERPT_LENGTH=$(parse_config "excerpt_length")
FOOTER_LINES=$(parse_config_array "footer_lines")

: "${POSTS_PER_PAGE:=10}"
: "${EXCERPT_LENGTH:=200}"

# =============================================================================
# YAML Frontmatter Parser
# =============================================================================

extract_frontmatter() {
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

extract_body() {
    local file="$1"
    sed -n '/^---$/,/^---$/!p' "$file" | tail -n +1
}

get_yaml_value() {
    local yaml="$1"
    local key="$2"
    local value=$(echo "$yaml" | grep "^${key}:" | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")
    
    # Handle inline array format: [item1, item2] - return first item
    if [[ "$value" =~ ^\[.*\]$ ]]; then
        value=$(echo "$value" | sed 's/^\[//;s/\]$//' | cut -d',' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//')
    fi
    echo "$value"
}

get_yaml_array() {
    local yaml="$1"
    local key="$2"
    local in_array=0
    local result=""
    
    # Check for inline array format: key: [item1, item2]
    local inline=$(echo "$yaml" | grep "^${key}:[[:space:]]*\[" | sed "s/^${key}:[[:space:]]*\[//;s/\].*$//")
    if [[ -n "$inline" ]]; then
        echo "$inline" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//'
        return
    fi
    
    # Multi-line array format
    while IFS= read -r line; do
        if [[ "$line" =~ ^${key}: ]]; then
            in_array=1
            continue
        fi
        if [[ $in_array -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                local item=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^"//;s/"$//')
                result="${result}${item}"$'\n'
            elif [[ ! "$line" =~ ^[[:space:]] ]] && [[ -n "$line" ]]; then
                break
            fi
        fi
    done <<< "$yaml"
    echo -n "$result"
}

# =============================================================================
# Date Formatting
# =============================================================================

format_date() {
    local date="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -j -f "%Y-%m-%d" "$date" "+%B %d, %Y" 2>/dev/null || echo "$date"
    else
        date -d "$date" "+%B %d, %Y" 2>/dev/null || echo "$date"
    fi
}

format_date_rss() {
    local date="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -j -f "%Y-%m-%d" "$date" "+%a, %d %b %Y 00:00:00 GMT" 2>/dev/null || echo "$date"
    else
        date -d "$date" "+%a, %d %b %Y 00:00:00 GMT" 2>/dev/null || echo "$date"
    fi
}

# =============================================================================
# URL Helpers
# =============================================================================

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

html_escape() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

strip_markdown() {
    local text="$1"
    # Remove markdown links: [text](url) -> text
    # Use perl for more reliable regex matching
    if command -v perl >/dev/null 2>&1; then
        # Remove complete markdown links: [text](url) -> text
        text=$(echo "$text" | perl -pe 's/\[([^\]]+)\]\([^)]+\)/\1/g')
        # Remove incomplete markdown links (truncated): [text](url or [text] -> text
        text=$(echo "$text" | perl -pe 's/\[([^\]]+)\]\([^)]*$/\1/g')
        text=$(echo "$text" | perl -pe 's/\[([^\]]+)\]$/\1/g')
        # Remove markdown images: ![alt](url) -> alt
        text=$(echo "$text" | perl -pe 's/!\[([^\]]+)\]\([^)]+\)/\1/g')
        # Remove incomplete markdown images: ![alt](url or ![alt] -> alt
        text=$(echo "$text" | perl -pe 's/!\[([^\]]+)\]\([^)]*$/\1/g')
        text=$(echo "$text" | perl -pe 's/!\[([^\]]+)\]$/\1/g')
        # Remove bold: **text** -> text
        text=$(echo "$text" | perl -pe 's/\*\*([^*]+)\*\*/\1/g')
        # Remove italic: *text* -> text (but not **text**)
        text=$(echo "$text" | perl -pe 's/(?<!\*)\*([^*]+)\*(?!\*)/\1/g')
        # Remove inline code: `code` -> code
        text=$(echo "$text" | perl -pe 's/`([^`]+)`/\1/g')
        # Remove reference-style links: [text][ref] -> text
        text=$(echo "$text" | perl -pe 's/\[([^\]]+)\]\[[^\]]+\]/\1/g')
        # Remove incomplete reference-style links: [text][ref or [text] -> text
        text=$(echo "$text" | perl -pe 's/\[([^\]]+)\]\[[^\]]*$/\1/g')
    else
        # Fallback to sed (less reliable but should work for most cases)
        text=$(echo "$text" | sed 's/\[\([^]]*\)\]([^)]*)/\1/g')
        text=$(echo "$text" | sed 's/\[\([^]]*\)\]([^)]*$/\1/g')
        text=$(echo "$text" | sed 's/\[\([^]]*\)\]$/\1/g')
        text=$(echo "$text" | sed 's/!\[\([^]]*\)\]([^)]*)/\1/g')
        text=$(echo "$text" | sed 's/!\[\([^]]*\)\]([^)]*$/\1/g')
        text=$(echo "$text" | sed 's/!\[\([^]]*\)\]$/\1/g')
        text=$(echo "$text" | sed 's/\*\*\([^*]*\)\*\*/\1/g')
        text=$(echo "$text" | sed 's/`\([^`]*\)`/\1/g')
        text=$(echo "$text" | sed 's/\[\([^]]*\)\]\[[^]]*\]/\1/g')
        text=$(echo "$text" | sed 's/\[\([^]]*\)\]\[[^]]*$/\1/g')
    fi
    echo "$text"
}

# =============================================================================
# HTML Templates
# =============================================================================

generate_head() {
    local title="$1"
    local description="${2:-$SITE_DESCRIPTION}"
    local featured="${3:-$PROFILE_IMAGE}"
    local canonical_url="${4:-$BASE_URL}"
    
    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$(html_escape "$title")</title>
    <meta name="description" content="$(html_escape "$description")">
    <meta name="author" content="$(html_escape "$AUTHOR_NAME")">
    
    <!-- Open Graph -->
    <meta property="og:type" content="website">
    <meta property="og:title" content="$(html_escape "$title")">
    <meta property="og:description" content="$(html_escape "$description")">
    <meta property="og:url" content="$(html_escape "$canonical_url")">
    <meta property="og:image" content="${BASE_URL}${featured}">
    <meta property="og:site_name" content="$(html_escape "$SITE_TITLE")">
    
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="$(html_escape "$title")">
    <meta name="twitter:description" content="$(html_escape "$description")">
    <meta name="twitter:image" content="${BASE_URL}${featured}">
    
    <link rel="canonical" href="$(html_escape "$canonical_url")">
    <link rel="alternate" type="application/rss+xml" title="$(html_escape "$SITE_TITLE") RSS Feed" href="${BASE_URL}/index.xml">
    <link rel="stylesheet" href="/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.1/css/all.min.css">
    <link rel="icon" href="/favicon.ico">
</head>
EOF
}

generate_sidebar() {
    cat <<EOF
    <aside class="sidebar">
        <div class="sidebar-content">
            <a href="/" class="profile-link">
                <img src="$PROFILE_IMAGE" alt="$(html_escape "$AUTHOR_NAME")" class="profile-image">
            </a>
            <a href="/" class="author-name-link">
                <h1 class="author-name">$(html_escape "$AUTHOR_NAME")</h1>
            </a>
            <p class="author-description">$(html_escape "$AUTHOR_DESCRIPTION")</p>
            <nav class="social-links">
                <a href="${BASE_URL}/index.xml" rel="alternate" type="application/rss+xml" aria-label="RSS Feed">
                    <i class="fas fa-rss"></i>
                </a>
                <a href="$GITHUB_URL" target="_blank" rel="noopener" aria-label="GitHub">
                    <i class="fab fa-github"></i>
                </a>
                <a href="$LINKEDIN_URL" target="_blank" rel="noopener" aria-label="LinkedIn">
                    <i class="fab fa-linkedin"></i>
                </a>
                <a href="$BLUESKY_URL" target="_blank" rel="noopener" aria-label="Bluesky">
                    <i class="fab fa-bluesky"></i>
                </a>
            </nav>
        </div>
    </aside>
EOF
}

generate_footer() {
    local current_year=$(date +%Y)
    cat <<EOF
    <footer class="site-footer">
        <p>Copyright © ${current_year} $(html_escape "$AUTHOR_NAME")</p>
EOF
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo "        <p>$(html_escape "$line")</p>"
        fi
    done <<< "$FOOTER_LINES"
    cat <<EOF
    </footer>
EOF
}

# =============================================================================
# Post Card Generator (shared template for post lists)
# =============================================================================

generate_post_card() {
    local slug="$1"
    local title="$2"
    local date="$3"
    local featured="$4"
    local excerpt="$5"
    local category="$6"
    local tags="$7"
    
    local formatted_date=$(format_date "$date")
    
    cat <<EOF
        <article class="post-card">
            <a href="/post/$slug/" class="post-link">
EOF
    if [[ -n "$featured" ]]; then
        cat <<EOF
                <div class="post-thumbnail">
                    <img src="$featured" alt="$(html_escape "$title")" loading="lazy">
                </div>
EOF
    fi
    cat <<EOF
                <div class="post-content">
                    <h2 class="post-title">$(html_escape "$title")</h2>
                    <div class="post-meta-inline">
                        <time class="post-date" datetime="$date">$formatted_date</time>
EOF
    if [[ -n "$category" ]]; then
        local cat_slug=$(slugify "$category")
        local cat_upper=$(echo "$category" | tr '[:lower:]' '[:upper:]')
        cat <<EOF
                        <span class="post-category"><a href="/category/$cat_slug/"><i class="fas fa-folder"></i> $(html_escape "$cat_upper")</a></span>
EOF
    fi
    if [[ -n "$tags" ]]; then
        echo '                        <div class="post-tags">'
        # Handle both comma-separated and newline-separated tags
        echo "$tags" | tr ',' '\n' | while IFS= read -r tag; do
            if [[ -n "$tag" ]]; then
                tag=$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [[ -n "$tag" ]]; then
                    local tag_slug=$(slugify "$tag")
                    echo "                            <a href=\"/tag/$tag_slug/\" class=\"tag\">#$(html_escape "$tag")</a>"
                fi
            fi
        done
        echo '                        </div>'
    fi
    cat <<EOF
                    </div>
EOF
    if [[ -n "$excerpt" ]]; then
        cat <<EOF
                    <p class="post-excerpt">$(html_escape "$excerpt")</p>
EOF
    fi
    cat <<EOF
                </div>
            </a>
        </article>
EOF
}

# =============================================================================
# Pagination Generator
# =============================================================================

generate_pagination() {
    local current_page="$1"
    local total_pages="$2"
    local base_path="$3"  # e.g., "" for index, "/category/r" for category pages
    
    if [[ $total_pages -le 1 ]]; then
        return
    fi
    
    echo '        <nav class="pagination">'
    
    # Previous link
    if [[ $current_page -gt 1 ]]; then
        local prev_page=$((current_page - 1))
        if [[ $prev_page -eq 1 ]]; then
            echo "            <a href=\"${base_path}/\" class=\"pagination-link prev\">&larr; Newer</a>"
        else
            echo "            <a href=\"${base_path}/page/${prev_page}/\" class=\"pagination-link prev\">&larr; Newer</a>"
        fi
    else
        echo '            <span class="pagination-link prev disabled">&larr; Newer</span>'
    fi
    
    # Page numbers
    echo '            <span class="pagination-numbers">'
    for ((i=1; i<=total_pages; i++)); do
        if [[ $i -eq $current_page ]]; then
            echo "                <span class=\"pagination-current\">$i</span>"
        elif [[ $i -eq 1 ]]; then
            echo "                <a href=\"${base_path}/\">$i</a>"
        else
            echo "                <a href=\"${base_path}/page/${i}/\">$i</a>"
        fi
    done
    echo '            </span>'
    
    # Next link
    if [[ $current_page -lt $total_pages ]]; then
        local next_page=$((current_page + 1))
        echo "            <a href=\"${base_path}/page/${next_page}/\" class=\"pagination-link next\">Older &rarr;</a>"
    else
        echo '            <span class="pagination-link next disabled">Older &rarr;</span>'
    fi
    
    echo '        </nav>'
}

# =============================================================================
# Taxonomies Generator (Categories & Tags sidebar)
# =============================================================================

generate_taxonomies() {
    if [[ -n "$ALL_CATEGORY" || -n "$ALL_TAGS" ]]; then
        echo '            <aside class="taxonomies">'
        if [[ -n "$ALL_CATEGORY" ]]; then
            echo '                <div class="taxonomy-section">'
            echo '                    <h3>Categories</h3>'
            echo '                    <ul class="taxonomy-list">'
            echo "$ALL_CATEGORY" | sort -u | while IFS= read -r cat; do
                if [[ -n "$cat" ]]; then
                    local cat_slug=$(slugify "$cat")
                    local cat_upper=$(echo "$cat" | tr '[:lower:]' '[:upper:]')
                    echo "                        <li><a href=\"/category/$cat_slug/\"><i class=\"fas fa-folder\"></i> $(html_escape "$cat_upper")</a></li>"
                fi
            done
            echo '                    </ul>'
            echo '                </div>'
        fi
        if [[ -n "$ALL_TAGS" ]]; then
            echo '                <div class="taxonomy-section">'
            echo '                    <h3>Tags</h3>'
            echo '                    <ul class="taxonomy-list tags-cloud">'
            echo "$ALL_TAGS" | sort -u | while IFS= read -r tag; do
                if [[ -n "$tag" ]]; then
                    local tag_slug=$(slugify "$tag")
                    echo "                        <li><a href=\"/tag/$tag_slug/\">#$(html_escape "$tag")</a></li>"
                fi
            done
            echo '                    </ul>'
            echo '                </div>'
        fi
        echo '            </aside>'
    fi
}

# =============================================================================
# List Page Generator (shared for index, category, tag pages)
# =============================================================================

generate_list_page() {
    local page_title="$1"
    local page_description="$2"
    local output_dir="$3"
    local base_path="$4"
    local posts_json="$5"  # newline-separated: slug|title|date|featured|excerpt|category|tags
    local current_page="$6"
    
    local total_posts=$(echo "$posts_json" | grep -c '|' || echo 0)
    local total_pages=$(( (total_posts + POSTS_PER_PAGE - 1) / POSTS_PER_PAGE ))
    [[ $total_pages -lt 1 ]] && total_pages=1
    
    local start_idx=$(( (current_page - 1) * POSTS_PER_PAGE + 1 ))
    local end_idx=$(( current_page * POSTS_PER_PAGE ))
    
    mkdir -p "$output_dir"
    
    local output_file="$output_dir/index.html"
    
    {
        generate_head "$page_title" "$page_description"
        echo '<body>'
        echo '    <div class="container">'
        generate_sidebar
        echo '        <main class="main-content">'
        # Only show page header if not an index page (base_path is empty for all index pages)
        if [[ -n "$base_path" ]]; then
            echo "            <header class=\"page-header\">"
            echo "                <h1>$(html_escape "$page_title")</h1>"
            if [[ -n "$page_description" ]] && [[ "$page_title" != "$SITE_TITLE" ]]; then
                echo "                <p>$(html_escape "$page_description")</p>"
            fi
            echo "            </header>"
        fi
        echo '            <div class="posts-list">'
        
        local line_num=0
        while IFS='|' read -r slug title date featured excerpt category tags; do
            line_num=$((line_num + 1))
            if [[ $line_num -ge $start_idx ]] && [[ $line_num -le $end_idx ]]; then
                generate_post_card "$slug" "$title" "$date" "$featured" "$excerpt" "$category" "$tags"
            fi
        done <<< "$posts_json"
        
        echo '            </div>'
        
        generate_pagination "$current_page" "$total_pages" "$base_path"
        
        # Category and tags sidebar (on all list pages)
        generate_taxonomies
        
        echo '        </main>'
        echo '    </div>'
        generate_footer
        echo '</body>'
        echo '</html>'
    } > "$output_file"
}

# =============================================================================
# Post Page Generator
# =============================================================================

generate_post_page() {
    local slug="$1"
    local title="$2"
    local date="$3"
    local featured="$4"
    local category="$5"
    local tags="$6"
    local content="$7"
    local prev_slug="$8"
    local prev_title="$9"
    local next_slug="${10}"
    local next_title="${11}"
    
    local formatted_date=$(format_date "$date")
    local post_dir="$DIST_DIR/post/$slug"
    mkdir -p "$post_dir"
    
    # Get first paragraph as description
    local description=$(echo "$content" | grep -m1 '^<p>' | sed 's/<[^>]*>//g' | head -c 160 || echo "")
    
    {
        generate_head "$title - $SITE_TITLE" "$description" "$featured" "${BASE_URL}/post/${slug}/"
        echo '<body>'
        echo '    <div class="container">'
        generate_sidebar
        echo '        <main class="main-content">'
        echo '            <article class="post-full">'
        echo '                <header class="post-header">'
        echo "                    <h1 class=\"post-title\">$(html_escape "$title")</h1>"
        echo '                    <div class="post-meta">'
        echo "                        <time datetime=\"$date\">$formatted_date</time>"
        if [[ -n "$category" ]]; then
            local cat_slug=$(slugify "$category")
            local cat_upper=$(echo "$category" | tr '[:lower:]' '[:upper:]')
            echo "                        <span class=\"post-category\"><a href=\"/category/$cat_slug/\"><i class=\"fas fa-folder\"></i> $(html_escape "$cat_upper")</a></span>"
        fi
        echo '                    </div>'
        if [[ -n "$tags" ]]; then
            echo '                    <div class="post-tags">'
            while IFS= read -r tag; do
                if [[ -n "$tag" ]]; then
                    local tag_slug=$(slugify "$tag")
                    echo "                        <a href=\"/tag/$tag_slug/\" class=\"tag\">#$(html_escape "$tag")</a>"
                fi
            done <<< "$tags"
            echo '                    </div>'
        fi
        echo '                </header>'
        if [[ -n "$featured" ]]; then
            echo "                <figure class=\"post-thumbnail-full\">"
            echo "                    <img src=\"$featured\" alt=\"$(html_escape "$title")\">"
            echo "                </figure>"
        fi
        echo '                <div class="post-body">'
        echo "$content"
        echo '                </div>'
        echo '                <nav class="post-navigation">'
        if [[ -n "$prev_slug" ]]; then
            echo "                    <a href=\"/post/$prev_slug/\" class=\"nav-prev\">"
            echo "                        <span class=\"nav-label\">&larr; Previous</span>"
            echo "                        <span class=\"nav-title\">$(html_escape "$prev_title")</span>"
            echo "                    </a>"
        else
            echo '                    <span class="nav-prev disabled"></span>'
        fi
        if [[ -n "$next_slug" ]]; then
            echo "                    <a href=\"/post/$next_slug/\" class=\"nav-next\">"
            echo "                        <span class=\"nav-label\">Next &rarr;</span>"
            echo "                        <span class=\"nav-title\">$(html_escape "$next_title")</span>"
            echo "                    </a>"
        else
            echo '                    <span class="nav-next disabled"></span>'
        fi
        echo '                </nav>'
        echo '            </article>'
        echo '        </main>'
        echo '    </div>'
        generate_footer
        echo '</body>'
        echo '</html>'
    } > "$post_dir/index.html"
}

# =============================================================================
# RSS Feed Generator
# =============================================================================

generate_rss() {
    local posts_data="$1"  # newline-separated: slug|title|date|featured|excerpt
    
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">'
        echo '  <channel>'
        echo "    <title>$(html_escape "$SITE_TITLE")</title>"
        echo "    <link>$BASE_URL</link>"
        echo "    <description>$(html_escape "$SITE_DESCRIPTION")</description>"
        echo "    <language>en-us</language>"
        echo "    <atom:link href=\"$BASE_URL/index.xml\" rel=\"self\" type=\"application/rss+xml\"/>"
        
        while IFS='|' read -r slug title date featured excerpt; do
            if [[ -n "$slug" ]]; then
                local pub_date=$(format_date_rss "$date")
                echo '    <item>'
                echo "      <title>$(html_escape "$title")</title>"
                echo "      <link>$BASE_URL/post/$slug/</link>"
                echo "      <guid>$BASE_URL/post/$slug/</guid>"
                echo "      <pubDate>$pub_date</pubDate>"
                if [[ -n "$excerpt" ]]; then
                    echo "      <description>$(html_escape "$excerpt")</description>"
                fi
                if [[ -n "$featured" ]]; then
                    echo "      <enclosure url=\"$BASE_URL$featured\" type=\"image/jpeg\"/>"
                fi
                echo '    </item>'
            fi
        done <<< "$posts_data"
        
        echo '  </channel>'
        echo '</rss>'
    } > "$DIST_DIR/index.xml"
}

# =============================================================================
# Sitemap Generator
# =============================================================================

generate_sitemap() {
    local posts_data="$1"  # newline-separated: slug|date
    
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
        
        # Index page
        echo '  <url>'
        echo "    <loc>$BASE_URL/</loc>"
        echo '    <changefreq>daily</changefreq>'
        echo '    <priority>1.0</priority>'
        echo '  </url>'
        
        # Post pages
        while IFS='|' read -r slug date rest; do
            if [[ -n "$slug" ]]; then
                echo '  <url>'
                echo "    <loc>$BASE_URL/post/$slug/</loc>"
                echo "    <lastmod>$date</lastmod>"
                echo '    <changefreq>monthly</changefreq>'
                echo '    <priority>0.8</priority>'
                echo '  </url>'
            fi
        done <<< "$posts_data"
        
        # Category pages
        echo "$ALL_CATEGORY" | sort -u | while IFS= read -r cat; do
            if [[ -n "$cat" ]]; then
                local cat_slug=$(slugify "$cat")
                echo '  <url>'
                echo "    <loc>$BASE_URL/category/$cat_slug/</loc>"
                echo '    <changefreq>weekly</changefreq>'
                echo '    <priority>0.6</priority>'
                echo '  </url>'
            fi
        done
        
        # Tag pages
        echo "$ALL_TAGS" | sort -u | while IFS= read -r tag; do
            if [[ -n "$tag" ]]; then
                local tag_slug=$(slugify "$tag")
                echo '  <url>'
                echo "    <loc>$BASE_URL/tag/$tag_slug/</loc>"
                echo '    <changefreq>weekly</changefreq>'
                echo '    <priority>0.5</priority>'
                echo '  </url>'
            fi
        done
        
        echo '</urlset>'
    } > "$DIST_DIR/sitemap.xml"
}

# =============================================================================
# 404 Page Generator
# =============================================================================

generate_404() {
    {
        generate_head "Page Not Found - $SITE_TITLE"
        echo '<body>'
        echo '    <div class="container">'
        generate_sidebar
        echo '        <main class="main-content">'
        echo '            <article class="error-page">'
        echo '                <h1>404</h1>'
        echo '                <p>Page not found</p>'
        echo '                <p>The page you&apos;re looking for doesn&apos;t exist or has been moved.</p>'
        echo '                <a href="/" class="back-home">← Back to Home</a>'
        echo '            </article>'
        echo '        </main>'
        echo '    </div>'
        generate_footer
        echo '</body>'
        echo '</html>'
    } > "$DIST_DIR/404.html"
}

# =============================================================================
# Main Build Process
# =============================================================================

echo "🔧 Building static site..."

# Step 1: Clear and recreate dist/
echo "📁 Clearing dist directory..."
# Safety check: Only remove dist/ if it's actually within the script directory
if [[ "$DIST_DIR" == "$SCRIPT_DIR"/* ]] && [[ -d "$SCRIPT_DIR" ]]; then
    rm -rf "$DIST_DIR"
else
    echo "Error: DIST_DIR ($DIST_DIR) is not within SCRIPT_DIR ($SCRIPT_DIR). Aborting to prevent accidental deletion." >&2
    exit 1
fi
mkdir -p "$DIST_DIR"

# Step 1.5: Setup build cache directory
CACHE_DIR="$SCRIPT_DIR/.build_cache"
mkdir -p "$CACHE_DIR"

# Step 2: Copy static files
echo "📦 Copying static files..."
if [[ -d "$STATIC_DIR" ]]; then
    cp -r "$STATIC_DIR"/* "$DIST_DIR/"
fi

# Step 3: Copy style.css
echo "🎨 Copying stylesheet..."
if [[ -f "$SCRIPT_DIR/style.css" ]]; then
    cp "$SCRIPT_DIR/style.css" "$DIST_DIR/"
fi

# Step 4: Parse all posts and collect metadata
echo "📝 Processing posts..."

declare -a POST_SLUGS
declare -a POST_TITLES
declare -a POST_DATES
declare -a POST_FEATURED
declare -a POST_EXCERPTS
declare -a POST_CATEGORY
declare -a POST_TAGS
declare -a POST_CONTENTS
declare -a POST_SOURCE_DIRS

ALL_CATEGORY=""
ALL_TAGS=""

# Find all markdown files (excluding _index.md files which are Hugo section files)
post_files=()
while IFS= read -r -d '' file; do
    # Skip _index.md files (Hugo section index files)
    if [[ "$(basename "$file")" == "_index.md" ]]; then
        continue
    fi
    post_files+=("$file")
done < <(find "$CONTENT_DIR" -name "*.md" -type f -print0 2>/dev/null || true)

# Handle empty posts directory gracefully
if [[ ${#post_files[@]} -eq 0 ]]; then
    echo "⚠️  Warning: No markdown files found in $CONTENT_DIR"
    echo "   Continuing with empty site..."
fi

for post_file in "${post_files[@]}"; do
    # Check if file uses YAML frontmatter (---) not TOML (+++)
    if ! head -1 "$post_file" | grep -q '^---$'; then
        echo "  Skipping (not YAML frontmatter): $post_file"
        continue
    fi
    
    frontmatter=$(extract_frontmatter "$post_file")
    
    # Check for draft
    draft=$(get_yaml_value "$frontmatter" "draft")
    if [[ "$draft" == "true" ]]; then
        echo "  Skipping draft: $post_file"
        continue
    fi
    
    slug=$(get_yaml_value "$frontmatter" "slug")
    title=$(get_yaml_value "$frontmatter" "title")
    date=$(get_yaml_value "$frontmatter" "date")
    featured=$(get_yaml_value "$frontmatter" "featured")
    
    # Handle category - can be array or single value (backward compatibility with "categories")
    category=$(get_yaml_value "$frontmatter" "category")
    if [[ -z "$category" ]]; then
        # Backward compatibility: check for old "categories" field
        category=$(get_yaml_value "$frontmatter" "categories")
        if [[ -z "$category" ]]; then
            category=$(get_yaml_array "$frontmatter" "categories" | head -1)
        fi
    fi
    
    tags=$(get_yaml_array "$frontmatter" "tags")
    
    # Normalize tags to lowercase (case-insensitive)
    if [[ -n "$tags" ]]; then
        normalized_tags=""
        while IFS= read -r tag; do
            if [[ -n "$tag" ]]; then
                normalized_tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]')
                normalized_tags="${normalized_tags}${normalized_tag}"$'\n'
            fi
        done <<< "$tags"
        tags="$normalized_tags"
    fi
    
    # Skip if missing required fields
    if [[ -z "$slug" ]] || [[ -z "$title" ]] || [[ -z "$date" ]]; then
        echo "  Skipping (missing slug/title/date): $post_file"
        continue
    fi
    
    echo "  Processing: $title"
    
    # Extract body and convert to HTML
    body=$(extract_body "$post_file")
    
    # Get excerpt from markdown body (first paragraph, before HTML conversion)
    # Skip headings, code blocks, and empty lines, get first real paragraph
    excerpt=$(echo "$body" | awk -v max_len="$EXCERPT_LENGTH" '
        BEGIN { skip=1; para="" }
        /^```/ { skip=1; next }
        /^#/ { next }  # Skip headings
        /^$/ { 
            if (para != "" && length(para) > 50) exit
            para = ""
            next 
        }
        /^[A-Z]/ || /^[a-z]/ || /^\[/ {  # Start of paragraph (letter or markdown link)
            if (para != "") para = para " "
            para = para $0
            if (length(para) > max_len) {
                para = substr(para, 1, max_len - 3) "..."
                exit
            }
        }
        { 
            if (para != "" && !/^[#\*\-]/) {
                para = para " " $0
                if (length(para) > max_len) {
                    para = substr(para, 1, max_len - 3) "..."
                    exit
                }
            }
        }
        END { 
            if (para == "") {
                # Fallback: get first non-empty line that starts with a letter or [
                para = $0
            }
            print para
        }
    ' | head -c "$EXCERPT_LENGTH" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Strip markdown syntax from excerpt to get plain text
    excerpt=$(strip_markdown "$excerpt")
    
    # If excerpt is near the limit, add ellipsis
    ellipsis_threshold=$((EXCERPT_LENGTH - 5))
    if [[ ${#excerpt} -ge $ellipsis_threshold ]]; then
        excerpt="${excerpt}..."
    fi
    
    # Get directory of post for relative images
    post_dir=$(dirname "$post_file")
    
    # Compute hash of markdown body for caching
    if command -v sha256sum >/dev/null 2>&1; then
        file_hash=$(echo "$body" | sha256sum | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
        file_hash=$(echo "$body" | shasum -a 256 | cut -d' ' -f1)
    else
        # Fallback: use md5 if neither is available (less secure but better than nothing)
        file_hash=$(echo "$body" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$body" | md5 | cut -d' ' -f1)
    fi
    cache_file="$CACHE_DIR/${file_hash}.html"
    
    # Check cache first
    if [[ -f "$cache_file" ]]; then
        content=$(cat "$cache_file")
        echo "    ✓ Using cached HTML"
    else
        # Convert markdown to HTML with pandoc (with syntax highlighting)
        content=$(echo "$body" | pandoc \
            --from markdown \
            --to html5 \
            --highlight-style=pygments 2>/dev/null || echo "$body" | pandoc --from markdown --to html5 2>/dev/null || echo "<p>Error processing content</p>")
        
        # Cache the result
        echo "$content" > "$cache_file"
        echo "    → Cached HTML"
    fi
    
    # Store post data
    POST_SLUGS+=("$slug")
    POST_TITLES+=("$title")
    POST_DATES+=("$date")
    POST_FEATURED+=("$featured")
    POST_EXCERPTS+=("$excerpt")
    POST_CATEGORY+=("$category")
    POST_TAGS+=("$tags")
    POST_CONTENTS+=("$content")
    POST_SOURCE_DIRS+=("$post_dir")
    
    # Collect category and tags
    if [[ -n "$category" ]]; then
        ALL_CATEGORY="${ALL_CATEGORY}${category}"$'\n'
    fi
    while IFS= read -r tag; do
        if [[ -n "$tag" ]]; then
            ALL_TAGS="${ALL_TAGS}${tag}"$'\n'
        fi
    done <<< "$tags"
done

# Sort posts by date (newest first)
echo "🔄 Sorting posts by date..."

# Create index array for sorting
num_posts=${#POST_SLUGS[@]}
indices=()
for ((i=0; i<num_posts; i++)); do
    indices+=("$i")
done

# Bubble sort by date (descending) - only if we have posts
if [[ $num_posts -gt 1 ]]; then
    for ((i=0; i<num_posts-1; i++)); do
        for ((j=0; j<num_posts-i-1; j++)); do
            idx1=${indices[$j]}
            idx2=${indices[$((j+1))]}
            if [[ "${POST_DATES[$idx1]}" < "${POST_DATES[$idx2]}" ]]; then
                indices[$j]=$idx2
                indices[$((j+1))]=$idx1
            fi
        done
    done
fi

# Step 5: Generate individual post pages
echo "📄 Generating post pages..."

for ((i=0; i<num_posts; i++)); do
    idx=${indices[$i]}
    
    # Get previous and next posts
    prev_slug=""
    prev_title=""
    next_slug=""
    next_title=""
    
    if [[ $i -gt 0 ]]; then
        prev_idx=${indices[$((i-1))]}
        next_slug="${POST_SLUGS[$prev_idx]}"
        next_title="${POST_TITLES[$prev_idx]}"
    fi
    if [[ $i -lt $((num_posts-1)) ]]; then
        next_idx=${indices[$((i+1))]}
        prev_slug="${POST_SLUGS[$next_idx]}"
        prev_title="${POST_TITLES[$next_idx]}"
    fi
    
    generate_post_page \
        "${POST_SLUGS[$idx]}" \
        "${POST_TITLES[$idx]}" \
        "${POST_DATES[$idx]}" \
        "${POST_FEATURED[$idx]}" \
        "${POST_CATEGORY[$idx]}" \
        "${POST_TAGS[$idx]}" \
        "${POST_CONTENTS[$idx]}" \
        "$prev_slug" \
        "$prev_title" \
        "$next_slug" \
        "$next_title"
    
    # Copy post-specific assets (figs/, img/, etc.) to dist directory
    source_post_dir="${POST_SOURCE_DIRS[$idx]}"
    dist_post_dir="$DIST_DIR/post/${POST_SLUGS[$idx]}"
    if [[ -d "$source_post_dir" ]]; then
        # Copy common asset directories (figs, img, images)
        for asset_dir in figs img images; do
            if [[ -d "$source_post_dir/$asset_dir" ]]; then
                cp -r "$source_post_dir/$asset_dir" "$dist_post_dir/" 2>/dev/null || true
            fi
        done
        # Copy any loose image files in the post directory (not in subdirectories)
        find "$source_post_dir" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" \) ! -name "index.*" -exec cp {} "$dist_post_dir/" \; 2>/dev/null || true
    fi
done

# Step 6: Generate index pages
echo "📋 Generating index pages..."

# Build posts data string for list pages
posts_data=""
for ((i=0; i<num_posts; i++)); do
    idx=${indices[$i]}
    # Replace newlines in tags with commas for storage
    tags_inline=$(echo "${POST_TAGS[$idx]}" | tr '\n' ',' | sed 's/,$//')
    posts_data+="${POST_SLUGS[$idx]}|${POST_TITLES[$idx]}|${POST_DATES[$idx]}|${POST_FEATURED[$idx]}|${POST_EXCERPTS[$idx]}|${POST_CATEGORY[$idx]}|${tags_inline}"$'\n'
done
posts_data=$(echo "$posts_data" | sed '/^$/d')

# Main index page
total_pages=$(( (num_posts + POSTS_PER_PAGE - 1) / POSTS_PER_PAGE ))
[[ $total_pages -lt 1 ]] && total_pages=1

generate_list_page "$SITE_TITLE" "$SITE_DESCRIPTION" "$DIST_DIR" "" "$posts_data" 1

# Additional index pages for pagination
for ((page=2; page<=total_pages; page++)); do
    generate_list_page "$SITE_TITLE - Page $page" "$SITE_DESCRIPTION" "$DIST_DIR/page/$page" "" "$posts_data" "$page"
done

# Step 7: Generate category pages
echo "📂 Generating category pages..."

echo "$ALL_CATEGORY" | sort -u | while IFS= read -r cat; do
    if [[ -n "$cat" ]]; then
        cat_slug=$(slugify "$cat")
        
        # Filter posts by category
        cat_posts=""
        for ((i=0; i<num_posts; i++)); do
            idx=${indices[$i]}
            if [[ "${POST_CATEGORY[$idx]}" == "$cat" ]]; then
                tags_inline=$(echo "${POST_TAGS[$idx]}" | tr '\n' ',' | sed 's/,$//')
                cat_posts+="${POST_SLUGS[$idx]}|${POST_TITLES[$idx]}|${POST_DATES[$idx]}|${POST_FEATURED[$idx]}|${POST_EXCERPTS[$idx]}|${POST_CATEGORY[$idx]}|${tags_inline}"$'\n'
            fi
        done
        cat_posts=$(echo "$cat_posts" | sed '/^$/d')
        
        if [[ -n "$cat_posts" ]]; then
            cat_count=$(echo "$cat_posts" | wc -l | tr -d ' ')
            cat_total_pages=$(( (cat_count + POSTS_PER_PAGE - 1) / POSTS_PER_PAGE ))
            [[ $cat_total_pages -lt 1 ]] && cat_total_pages=1
            
            # Generate page 1
            generate_list_page "Category: $cat" "$cat_count posts in $cat" "$DIST_DIR/category/$cat_slug" "/category/$cat_slug" "$cat_posts" 1
            
            # Generate additional pages for pagination
            for ((page=2; page<=cat_total_pages; page++)); do
                generate_list_page "Category: $cat - Page $page" "$cat_count posts in $cat" "$DIST_DIR/category/$cat_slug/page/$page" "/category/$cat_slug" "$cat_posts" "$page"
            done
        fi
    fi
done

# Step 8: Generate tag pages
echo "🏷️  Generating tag pages..."

echo "$ALL_TAGS" | sort -u | while IFS= read -r tag; do
    if [[ -n "$tag" ]]; then
        tag_slug=$(slugify "$tag")
        
        # Filter posts by tag (case-insensitive comparison)
        tag_posts=""
        for ((i=0; i<num_posts; i++)); do
            idx=${indices[$i]}
            # Convert both to lowercase for case-insensitive comparison
            post_tags_lower=$(echo "${POST_TAGS[$idx]}" | tr '[:upper:]' '[:lower:]')
            tag_lower=$(echo "$tag" | tr '[:upper:]' '[:lower:]')
            if echo "$post_tags_lower" | grep -qx "$tag_lower"; then
                tags_inline=$(echo "${POST_TAGS[$idx]}" | tr '\n' ',' | sed 's/,$//')
                tag_posts+="${POST_SLUGS[$idx]}|${POST_TITLES[$idx]}|${POST_DATES[$idx]}|${POST_FEATURED[$idx]}|${POST_EXCERPTS[$idx]}|${POST_CATEGORY[$idx]}|${tags_inline}"$'\n'
            fi
        done
        tag_posts=$(echo "$tag_posts" | sed '/^$/d')
        
        if [[ -n "$tag_posts" ]]; then
            tag_count=$(echo "$tag_posts" | wc -l | tr -d ' ')
            tag_total_pages=$(( (tag_count + POSTS_PER_PAGE - 1) / POSTS_PER_PAGE ))
            [[ $tag_total_pages -lt 1 ]] && tag_total_pages=1
            
            # Generate page 1
            generate_list_page "Tag: #$tag" "$tag_count posts tagged with #$tag" "$DIST_DIR/tag/$tag_slug" "/tag/$tag_slug" "$tag_posts" 1
            
            # Generate additional pages for pagination
            for ((page=2; page<=tag_total_pages; page++)); do
                generate_list_page "Tag: #$tag - Page $page" "$tag_count posts tagged with #$tag" "$DIST_DIR/tag/$tag_slug/page/$page" "/tag/$tag_slug" "$tag_posts" "$page"
            done
        fi
    fi
done

# Step 9: Generate RSS feed
echo "📡 Generating RSS feed..."
rss_data=""
for ((i=0; i<num_posts && i<20; i++)); do
    idx=${indices[$i]}
    rss_data+="${POST_SLUGS[$idx]}|${POST_TITLES[$idx]}|${POST_DATES[$idx]}|${POST_FEATURED[$idx]}|${POST_EXCERPTS[$idx]}"$'\n'
done
generate_rss "$rss_data"

# Step 10: Generate sitemap
echo "🗺️  Generating sitemap..."
sitemap_data=""
for ((i=0; i<num_posts; i++)); do
    idx=${indices[$i]}
    sitemap_data+="${POST_SLUGS[$idx]}|${POST_DATES[$idx]}"$'\n'
done
generate_sitemap "$sitemap_data"

# Step 11: Generate 404 page
echo "🚫 Generating 404 page..."
generate_404

# Step 12: Copy favicon if present
if [[ -f "$STATIC_DIR/favicon.ico" ]]; then
    echo "🔖 Copying favicon..."
    cp "$STATIC_DIR/favicon.ico" "$DIST_DIR/"
fi

echo "✅ Build complete! Output in $DIST_DIR"
echo "   📊 Generated $num_posts posts"
echo "   📂 $(echo "$ALL_CATEGORY" | sort -u | grep -c . || echo 0) category"
echo "   🏷️  $(echo "$ALL_TAGS" | sort -u | grep -c . || echo 0) tags"

