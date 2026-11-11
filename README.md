# b1gZIP

b1gZIP is a PHP extension for creating ZIP archives, based on the ZipArchive C++ library from Artpol Software.

## PHP compatibility

This branch contains a PHP 8 API port. It has not been built or runtime-tested in this environment; successful use depends on compiling it against the PHP 8 development headers and a compatible Artpol ZipArchive library. Do not load a binary built for another PHP version.

## Requirements

- PHP 8 development headers, `phpize`, and the matching `php-config` (usually provided by the PHP development package)
- `g++`, `make`, and standard build tools
- Artpol ZipArchive C++ headers and library (`ZipArchive.h` and `libziparch`)

Extract the Artpol ZipArchive archive first. `ZipArchive.h` must be in the extracted directory you pass to `--with-b1gzip=DIR`. The linker expects the `ziparch` library in that directory; if the library is elsewhere, add its path to `LDFLAGS` (see below).

## Build with phpize and g++

Use the `phpize` and `php-config` belonging to the PHP version that will load the extension. Example for PHP 8.2, with `ZipArchive.h` and `libziparch` in `/opt/ZipArchive`:

```sh
phpize8.2
CXX=g++ ./configure --with-php-config=/usr/bin/php-config8.2 --with-b1gzip=/opt/ZipArchive
make -j"$(nproc)" CXX=g++
sudo make install
```

Replace `8.2` with the installed PHP 8 minor version and `/opt/ZipArchive` with the extracted ZipArchive directory containing `ZipArchive.h`. If `libziparch` is in a separate directory, provide its path, for example:

```sh
LDFLAGS="-L/opt/ZipArchive/lib" CXX=g++ ./configure --with-php-config=/usr/bin/php-config8.2 --with-b1gzip=/opt/ZipArchive
make -j"$(nproc)" CXX=g++
sudo make install
```

For dependencies installed in standard system paths:

```sh
phpize
CXX=g++ ./configure --with-php-config="$(command -v php-config)" --with-b1gzip
make -j"$(nproc)" CXX=g++
sudo make install
```

If `phpize` has already been run for another PHP version, clean the generated build files (`phpize --clean`) before regenerating them with the desired version.

Enable the installed extension in the configuration for that same PHP installation:

```ini
extension=b1gzip.so
```

Then check that PHP loads it:

```sh
php --ri b1gzip
```

For PHP-FPM, enable it in the FPM configuration and restart the corresponding FPM service. If the Artpol shared library is outside the system library paths, configure the dynamic linker (for example with `ldconfig`) or set the appropriate runtime library path so PHP can locate `libziparch`.

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
