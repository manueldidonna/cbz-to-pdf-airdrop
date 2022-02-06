# comics-converter

A command line tool written in Swift to convert **Comic Book Zip** archives to **PDF** and share them over AirDrop.

<img src="art/comics-converter-example.png?raw=true">

## Usage
### Swift Package Manager
You can run the script by using `$ swift run comics-converter`, but this works only if you are in the comics-converter/ directory. To run it from anywhere you have to copy the release binary to the user binary directory.
```
$ swift build -c release
$ cp .build/release/comics-converter /usr/local/bin/comics-converter
```
Then:
`$ comics-converter [<files> ...] [--airdrop] [--verbose-prints] [--output-directory <output-directory>]`
