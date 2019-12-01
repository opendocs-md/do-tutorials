# Digital Ocean tutorials in Markdown format

This repository contains a collection of [Digital Ocean Tutorials](https://www.digitalocean.com/community/tutorials/) converted to Markdown format.

There are several benefits to having a copy of the tutorials in a plaintext markup format, including:

* easy to access offline / when Internet is not available
* possible to search using grep and other plaintext tools
* can be easily converted to other formats (e.g., PDF), or back to HTML again
* good to have a backup of these important guides in case Digital Ocean experiences an outage or is not available for any reason
* facilitate translation of guides into other languages

The text of the tutorials is stored in the `md` folder in folders corresponding to the code of the language the tutorials are written in. Translations are currently available in the following languages:

ISO code | Language name
-------- | -------------
de | German
en | English
es | Spanish
fr | French
pt | Portuguese
ru | Russian
zh | Chinese

## Format

The tutorials in the `md` folder are plain Markdown files with metadata stored in a short frontmatter section at the beginning of each file.

The frontmatter section looks something like this:

    ---
    author: Brian Boucheron
    date: 2017-09-26
    language: en
    license: cc by-nc-sa
    source: https://www.digitalocean.com/community/tutorials/3-strategies-for-minimizing-downtime
    ---

As can be seen from the example above, the frontmatter contains metadata relating to the tutorial, including the name of the author(s), the date the tutorial was posted online, the (natural) language the tutorial is written in, the license, and a link to the original source file online. This should make it easy to parse the files automatically in order to extract metadata.

## Scripts

The `.do_to_md` script has a number of options to help batch convert and process HTML and Markdown files. If you have an HTML file of a tutorial (for example, `how-to-add-javascript-to-html.html`), you can convert it to Markdown easily by entering the `scripts` directory and issuing the following command:

    ./do_to_md.rb -f how-to-add-javascript-to-html.html > how-to-add-javascript-to-html.md

This will create a new Markdown file with the converted content of the original tutorial. (If this is an HTML tutorial that has not already been included in this repository, you could at this point also consider submitting a pull request to add it to the repo.)

To run the script you will need the [kramdown](https://kramdown.gettalong.org/) and [reverse_markdown](https://github.com/xijo/reverse_markdown) gems.

Available options for the script:

* `-b`, `--batch`: _Batch process all files in HTML directory_
* `-f`, `--filename FILE`: _Convert single HTML file to Markdown and print to STDOUT_
* `-h`, `--help`: _Print help message listing these options_
* `-i`, `--index`: _Generate index of all articles_
* `-j`, `--json`: _Print JSON metadata from original HTML file_
* `-l`, `--local-images`: _Convert remote image links to local ones_
* `-r`, `--remote-images`: _Convert local image links to remote ones_

## Media files

Associated images and other media files are stored in the [do-tutorials-images](https://github.com/opendocs-md/do-tutorials-images) repository.

There are several ways to view the tutorials and images together:

1. Download the images from the [do-tutorials-images](https://github.com/opendocs-md/do-tutorials-images) repository and move the `img` folder to the main project folder. Then convert all remote image links to local links using the script included in the `scripts` directory (`./do_to_md -l`). These can then be converted to HTML and viewed in a browser, or opened directly in any Markdown-compatible viewer.
2. Download a prepared zip archive with all the Markdown files and images together from the [releases](https://github.com/opendocs-md/do-tutorials/releases) section. This contains the same content that would result from following the instructions in step 1 above.
3. (Soon) Download generated PDF versions of the tutorials with images included.

## Contributing

Most of the tutorials available online can be found here. Please note however that this repository represents a snapshot of the online tutorials (covering a period from about 2012-2019) at a specific point in time, and is not updated with any regularity.

Nevertheless, if you notice any tutorials that are missing, please feel free to open an issue or PR so they can be added.

## License

All of the tutorial content in this repository has been released under a [CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/) license by Digital Ocean.

Scripts and other code: MIT.

CSS: [Water CSS](https://github.com/kognise/water.css) by @kognise
