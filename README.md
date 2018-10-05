# U7DCP (Ultima VII DOS Cache Patch)
U7DCP patches a bug in Ultima 7, where the game will enable L1 cache on launch and thus prevent the user from running with the cache disabled.

For more information, see comments in ```main.asm``` and peruse [Tarpeeksi Hyvae Soft's website](http://tarpeeksihyvaesoft.com/soft).

### Building
To assemble U7DCP for DOS, which is its only target, do ```fasm main.asm u7dcp.exe```.
