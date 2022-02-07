# mephisto

A command line tool written in Swift to convert **Comic Book Zip** archives to **PDF** and share them over AirDrop.

<img src="art/usage-example.png?raw=true">

## Usage
### Swift Package Manager
You can run the script by using `$ swift run mephisto`, but this works only if you are in the mephisto/ directory. To run it from anywhere you have to copy the release binary to the user binary directory.
```
$ git clone https://github.com/manueldidonna/mephisto.git
$ cd mephisto/
$ swift build -c release
$ cp .build/release/comics-converter /usr/local/bin/comics-converter
$ mephisto --help
```
