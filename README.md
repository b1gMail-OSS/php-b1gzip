# b1gZIP

b1gZIP is a PHP extension for creating ZIP archives, based on the ZipArchive C++ library from Artpol Software.

## PHP compatibility

This branch contains a PHP 8 API port. It has not been built or runtime-tested in this environment; successful use depends on compiling it against the PHP 8 development headers and a compatible Artpol ZipArchive library. Do not load a binary built for another PHP version.

## Requirements

- PHP 8 development headers, `phpize`, and the matching `php-config` (usually provided by the PHP development package)
- `g++`, `make`, and standard build tools
- Artpol ZipArchive headers and C++ source files from the extracted archive (`ZipArchive.h` plus the corresponding `.cpp` implementation files)
- The C++ runtime library (`libstdc++` on typical Linux systems)

The crucial point is that `ZipArchive.h` alone is not enough. The implementation classes `CZipArchive` and `CZipMemFile` must be compiled together with the PHP extension; otherwise the final `.so` will contain undefined vtable symbols such as `_ZTV11CZipMemFile`.

## Build with phpize and g++

Extract the Artpol ZipArchive package first. The directory you pass to `--with-b1gzip=DIR` must contain `ZipArchive.h` and the corresponding C++ implementation files. Example for PHP 8.2:

```sh
phpize8.2
CXX=g++ ./configure --with-php-config=/usr/bin/php-config8.2 --with-b1gzip=/opt/ZipArchive
make -j"$(nproc)" CXX=g++
sudo make install
```

This configuration compiles both `src/b1gzip.cpp` and all `.cpp` files from the extracted ZipArchive directory into the extension.

If `ZipArchive.h` is in a standard system include path, you can also use:

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
