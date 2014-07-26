
require 'scraperwiki'
require 'open-uri'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '/tmp/cache'

@PAGE = 'https://raw.githubusercontent.com/mysociety/theyworkforyou/master/classes/Policies.php'

def issue_from (line)
  return unless m = line.match( /(\d+) => '(.*)',?\s?$/ )
  return {
    id: m[1],
    text: m[2].gsub("\\'", "&rsquo;"),
  }
end

def find_policy_list (page_text)
  return page_text[/protected \$policies = array\((.*?)\);$/m, 1].split(/\n/).map { |line|
    issue_from(line)
  }.reject { |p| p.nil? }
end

def find_categories (page_text)
  lines = page_text.split(/\n/).select { |line|
    line if line =~ /private \$sets = array/ .. line =~ /\);/
  }
  lines.drop(1)
end

def scraped_policies
  cats = {}
  section = 'XXX'
  page_text = open(@PAGE).read
  find_categories(page_text).each do |line|
    if line =~ /'([^']+)' => array/
      section = $1
    else
      id = line[/(\d+)/, 1]
      next if id.nil?
      (cats[section] ||= []) << id
    end
  end

  find_policy_list(page_text).map { |i|
    {
      id: i[:id],
      text: i[:text],
      categories: cats.select { |k,v| v.include? i[:id] }.keys.join(","),
    }
  }
end

ScraperWiki.save_sqlite([:id], scraped_policies)


