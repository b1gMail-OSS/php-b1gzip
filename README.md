# b1gZIP

b1gZIP is a PHP extension for creating ZIP archives, based on the ZipArchive C++ library from Artpol Software.

## PHP compatibility

This branch contains a PHP 8 API port. It has not been built or runtime-tested in this environment; successful use depends on compiling it against the PHP 8 development headers and the Artpol ZipArchive library. Do not load a binary built for another PHP version.

## Requirements

- PHP 8 development headers, `phpize`, and the matching `php-config`
- `g++`, `make`, CMake, and standard build tools
- Artpol ZipArchive source archive: <https://www.artpol-software.com/Downloads/ziparchive_src.zip>

## Build Artpol ZipArchive

Extract the archive so that its source files, including `ZipArchive.h`, are in a directory named `ZipArchive`. Build from a `build` directory under that root:

```sh
cd ZipArchive
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DZIP_ENABLE_UNICODE=ON -DZIP_ENABLE_ZIP64=ON
cmake --build . --config Release
```

The expected static library output is `ZipArchive/bin/libZipArchive.a`.

## Build the PHP extension

Pass the `ZipArchive` root directory (the directory containing `ZipArchive.h`) to `--with-b1gzip`. `config.m4` links the static archive from its `bin/` subdirectory and the C++ standard library; it does not use `-lziparch`.

Example for PHP 8.2, assuming `ZipArchive` is at `/opt/ZipArchive`:

```sh
phpize8.2
CXX=g++ ./configure --with-php-config=/usr/bin/php-config8.2 --with-b1gzip=/opt/ZipArchive
make -j"$(nproc)" CXX=g++
sudo make install
```

Replace `8.2` with the PHP 8 minor version installed on the system. If `phpize` has already been run for another PHP version, run `phpize --clean` before regenerating the build files.

Enable the extension in the configuration for that same PHP installation:

```ini
extension=b1gzip.so
```

Check that PHP loads it:

```sh
php --ri b1gzip
```

If the linker reports relocation errors while linking `libZipArchive.a` into the shared PHP module, rebuild the ZipArchive static library with position-independent code enabled (for example by adding `-DCMAKE_POSITION_INDEPENDENT_CODE=ON` to its CMake configure command).

## Example

```php
<?php
if (!function_exists('b1gzip_create')) {
    die('b1gZIP is not installed');
}

$archive = b1gzip_create();
b1gzip_add($archive, 'This is a test!', 'test.txt');
b1gzip_add($archive, 'Another test!', 'demo/demo.txt');
$zip = b1gzip_final($archive);

header('Content-Type: application/zip');
header('Content-Disposition: attachment; filename="test.zip"');
header('Content-Length: ' . strlen($zip));
echo $zip;
```
