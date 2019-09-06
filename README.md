# PGET - A file downloader to bypass http proxy download limits

Download limits can be set up in most http proxies (e.g. squid). This script can be used to bypass those limits.

This is NOT a hack. This uses valid HTTP/1.1 flows. Tested for `squid-2.6` 

## Prerequisites

- `Perl`
- `curl`


## Usage

1. Edit the configuration in `pget.pl` (e.g. proxy settings)
2. Run `pget.pl -i <file>` giving a sample file of the same type that being downloaded. Required only once per each file type. 
e.g. To download `.tar` files
```
    # my.tar should be an actual file
    $ pget.pl -i my.tar 
```

3. To download a file, run `pget.pl -g <URL>`



## Licence

This work is licenced under GNU GPL. It simply says 
> 	You are hereby granted to do whatever you want with this except claiming you wrote this.
