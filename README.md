# b1gZIP

b1gZIP is a PHP extension for creating ZIP archives, based on the ZipArchive C++ library from Artpol Software.

## PHP compatibility

This branch contains a PHP 8 API port. It has not been built or runtime-tested in this environment; successful use depends on compiling it against the PHP 8 development headers and a compatible Artpol ZipArchive library. Do not load a binary built for another PHP version.

## Requirements

- PHP 8 development headers, `phpize`, and the matching `php-config` (usually provided by the PHP development package)
- `g++`, `make`, and standard build tools
- Artpol ZipArchive C++ headers (`ZipArchive.h`)

Extract the Artpol ZipArchive archive first. `ZipArchive.h` must be in the extracted directory you pass to `--with-b1gzip=DIR`. The build configuration intentionally does not add `-lziparch`. Ensure any required Artpol implementation is available to the final extension through your local build/link setup.

## Build with phpize and g++

Use the `phpize` and `php-config` belonging to the PHP version that will load the extension. Example for PHP 8.2, with `ZipArchive.h` in `/opt/ZipArchive`:

```sh
phpize8.2
CXX=g++ ./configure --with-php-config=/usr/bin/php-config8.2 --with-b1gzip=/opt/ZipArchive
make -j"$(nproc)" CXX=g++
sudo make install
```

Replace `8.2` with the installed PHP 8 minor version and `/opt/ZipArchive` with the extracted ZipArchive directory containing `ZipArchive.h`.

If `ZipArchive.h` is in a standard system include path:

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

For PHP-FPM, enable it in the FPM configuration and restart the corresponding FPM service. If the Artpol implementation has runtime shared-library dependencies, make sure the dynamic linker can locate those libraries.

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
