# Cache Bandwidth Test

This is a simple adaption of Zack Smiths [bandwidth](https://zsmith.co/bandwidth.php) benchmark. 
to be runnable on on x86 Linux, RV64 Linux and RV64 bare-metal (with explicit support for Cheshire).

By default running `make` builds only the RV64 Linux and RV64 bare-metal binaries.
To build the x86 Linux binary (which requires NASM) you can run:

    make bandwidth

To build only the RV64 Linux target use:

    make bandwidth-rv64

To build only the RV64 bare-metal Cheshire target use:

    // To update the Cheshire dependency
    git submodule update --init --recursive
    make bandwidth-rv64-chs
