#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'kramdown'
require 'optparse'
require 'reverse_markdown'

def extract_html(html)
  html
    .gsub(/.*<div class="content-body tutorial-content.*?" data-growable-markdown>/m, "")
    .gsub(/<div class="tutorial-footer">.*/m, "")
end

def clean_md(document)
  document
    .gsub(/^### Introduction/, "## Introduction")
    .gsub(/\]\(https:\/\/assets\.digitalocean\.com\/articles\/translateddiagrams32918\//, "](../../img/translateddiagrams32918/")
    .gsub(/\]\(https:\/\/assets\.digitalocean\.com\/articles\//, "](../../img/")
    .gsub(/\]\(https:\/\/www\.digitalocean\.com\/community\/tutorials\//, "](")
    .gsub(/\n\n+\Z/, "\n")
end

def get_json(html)
  if html.match(/<script type="application\/ld\+json">(.*?)<\/script>/m)
    match = Regexp::last_match[1]
    json = match.gsub(/^\n\s+/, "").gsub(/\n\s+$/, "")
    @json = JSON.parse(json)
  end
end

def get_licenses_only(json)
  puts json["license"]
end

def get_lang(json)
  lang = "en"
  if json["inLanguage"]
    lang = json["inLanguage"]
  end
  lang
end

def extract_tags(snippet)
  md = ReverseMarkdown.convert(snippet)
  splits = md.gsub(/^Posted in /, "").split(" | Tagged with ")
  categories, tags = splits

  c = []
  categories.split(", ").each do |item|
    c << item.gsub(/\[/, "").gsub(/\].*/, "")
  end
  out_c = "categories: " + c.join(", ") + "\n"

  t = []
  out_t = ""
  if tags
    tags.split(", ").each do |item|
      t << item.gsub(/\[/, "").gsub(/\].*/, "")
    end
    out_t = "tags: " + t.join(", ")
  end

  @lang = "en"
  if c.include?("french") then @lang = "fr" end
  @cattags = out_c + out_t.chomp

  blank = ""
  blank
end

def get_author(json)
#   author_array = json["author"][0]["name"]
  author_array = json["author"]
  author = ""
  len = author_array.length
  count = 0
  if len != 0
    author = author_array[0]["name"]
  end
  if len > 1
    author_array.each do |a|
      if count == 0
        count += 1
        next
      end
      author << ", " + a["name"]
    end
  end
  author
end

def file_to_md(file)
  basename = File.basename(file, ".html")
  html = File.read(file)
  get_json(html)
  source = "https://www.digitalocean.com/community/tutorials/" + basename
  headline = @json["headline"]
  author = get_author(@json)
  date = @json["datePublished"].gsub(/T.*/, "")
  lang = get_lang(@json)
  content = extract_html(html)
  document = ReverseMarkdown.convert(content)
  body = clean_md(document)
  frontmatter = "---\nauthor: #{author}\ndate: #{date}\nlanguage: #{lang}\nlicense: cc by-nc-sa\nsource: #{source}\n---"
  md_out = frontmatter.gsub(/\n\n+/, "\n") + "\n\n# " + headline + "\n\n" + body
  md_out
end

def print_json(options)
  file = options[:json]
  html = File.read(file)
  get_json(html)
  puts JSON.pretty_generate(@json)
end

def single_file_do(options)
  file = options[:filename]
  md_out = file_to_md(file)
  puts md_out
end

def batch_do
  files = Dir.glob("html/**/*").sort

  files.each do |f|
    if File.directory?(f)
      next
    end
    parent_dir = f.gsub(/^html\//, "").gsub(/\/.*?$/, "")

    base_out_dir = "md/" + parent_dir + "/"
    out_filename = base_out_dir + File.basename(f, ".html") + ".md"

    FileUtils.mkdir_p base_out_dir

    md_out = file_to_md(f)
    File.open(out_filename, "w") {|m| m << md_out }
  end
end

def local_images
  files = Dir.glob("../md/**/*.md")
  files.sort.each do |filepath|
    IO.write(filepath, File.open(filepath) do |f|
        f.read.gsub(/https:\/\/raw\.githubusercontent\.com\/opendocs\-md\/do\-tutorials\-images\/master\/img\//, "../../img/")
      end
    )
  end
end

def remote_images
  files = Dir.glob("../md/**/*.md")
  files.sort.each do |filepath|
    IO.write(filepath, File.open(filepath) do |f|
        f.read.gsub(/\]\(\.\.\/\.\.\/img\//, "](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/")
      end
    )
  end
end

def generate_index
  files = Dir.glob("../md/**/*.md")
  lang = ""
  index = ""
  files.sort.each do |filepath|
    basename = File.basename(filepath)
    content = File.read(filepath)
    l = File.split(File.absolute_path(filepath))[0].split("/").last
    if l != lang
      index << "\n## " + l + "\n\n"
      lang = l
    end
    /^# (?<title>.*)$/ =~ content
    index << "* [#{title}](#{filepath})\n"
  end
  docs = "../docs/"
  FileUtils.mkdir_p docs
  File.open(docs + "index.md", "w") {|f| f << "# DO Tutorials Index\n" + index }
  repo_base = "https://github.com/opendocs-md/do-tutorials/blob/master/md/"
  index_links = index.gsub(/\.\.\/md\//, repo_base)
  $content = Kramdown::Document.new(index_links).to_html
  html_out = ERB.new(File.read("template.rhtml")).result
  File.open(docs + "index.html", "w") {|f| f << html_out }
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: do_to_md.rb [options]"

  opts.on("-b", "--batch", "Batch process all files in HTML directory") { options[:batch] = true }
  opts.on("-f", "--filename FILE", "Convert single HTML file to Markdown and print to STDOUT") { |v| options[:filename] = v }
  opts.on("-i", "--index", "Generate index of all articles") { options[:index] = true }
  opts.on("-j", "--json", "Print JSON metadata") { options[:json] = true }
  opts.on("-l", "--local-images", "Convert remote image links to local ones") { options[:local] = true }
  opts.on("-r", "--remote-images", "Convert local image links to remote ones") { options[:remote] = true }

end.parse!

if options[:batch]
  batch_do
elsif options[:filename]
  single_file_do(options)
elsif options[:json]
  print_json(options)
elsif options[:local]
  local_images
elsif options[:remote]
  remote_images
elsif options[:index]
  generate_index
else
  abort("  Please provide at least one commandline option.")
end
