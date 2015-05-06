# `p`
## Python Version Management, Simplified.

![introduction](https://cloud.githubusercontent.com/assets/1139621/7488032/37f37308-f389-11e4-8995-89f7cba5ad8b.gif)

`p` is **powerful** and **feature-packed**, yet **simple**; both in setup and use. There are no tricky settings, options, or crazy dependencies. `p` is just a helpful ~600 line Bash script that gets the job done.

`p` was heavily inspired by [`n`, a version manager for Node.js](https://github.com/tj/n).

## Getting Started
After the [super painless drag-and-drop installation](#installation), you can [start using `p`](#usage) right away.

## Usage
```
Usage: p [COMMAND] [args]

Commands:

p                              Output versions installed
p status                       Output current status
p <version>                    Activate to Python <version>
	p latest                     Activate to the latest Python release
	p stable                     Activate to the latest stable Python release
p use <version> [args ...]     Execute Python <version> with [args ...]
p bin <version>                Output bin path for <version>
p rm <version ...>             Remove the given version(s)
p prev                         Revert to the previously activated version
p ls                           Output the versions of Python available
	p ls latest                  Output the latest Python version available
	p ls stable                  Output the latest stable Python version available

Options:

-V, --version   Output current version of p
-h, --help      Display help information
```

## Installation
After downloading the Bash script, simply copy it over to your `$PATH` and `p` will take care of the rest.
```sh
$ wget https://github.com/qw3rtman/p/releases/download/v0.1.0/j
$ chmod +x p
$ mv p /usr/local/bin
```

If you don't have `wget` on your system, you can download the `j` binary from the [releases page](https://github.com/qw3rtman/j/releases) and follow the above steps from the second one onward.

## Updating
Simply follow the above steps and swap out the old Bash script with the new one!

## Contributing
Contributions are always welcome.

Find something interesting in the TODO below, fork our code, create a new branch, and send us a pull request.

There are only two rules: avoid [code smells](http://blog.codinghorror.com/code-smells/) and abide by the syntax-formatting of the existing code.

## TODO
* **greater abstraction between Python 2.x.x and 3.x.x**

## FAQs
* How does `p` work?
  * `p` stores each Python version installed in `/usr/local/p/versions/python`. When a Python version is activated, `p` creates a symbolic link to the Python binary located at `/usr/local/p/versions/python/python`. Since `p` prefixes the $PATH with `/usr/local/p/versions/python`, this version of `python` is found first; hence, it is used over the default version of Python installed on your system.
* How do I revert back to my default Python version?
  * Simply run `p default` and `p` will remove the symbolic link described above; therefore reverting back to your default Python version.
* Does `p` download the source each time I activate or install a version?
  * Nope. `p` stores the source for each of the versions installed, allowing for quick activations between already-installed versions.

## Core Team
### Nimit Kalra
* <nimit@nimitkalra.com>
* <http://nimitkalra.com>
* <https://github.com/qw3rtman>
* <https://twitter.com/qw3rtman>
