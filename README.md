# b1gZIP

b1gZIP is a PHP extension for creating ZIP archives, based on the ZipArchive C++ library from Artpol Software.

## PHP compatibility

This branch contains a PHP 8 API port. It has not been built or runtime-tested in this environment. Build it against the PHP development headers for the PHP version that will load the extension.

## Requirements

- PHP 8 development headers, `phpize`, and the matching `php-config`
- `g++`, `make`, CMake, and standard build tools
- `curl` or `wget` and `unzip` for the automatic Artpol source download

## Build

Enabling the extension automatically downloads the Artpol source archive, configures and builds its static library with CMake, and then links it into b1gZIP. No separate ZipArchive build step is needed. The downloaded source and generated build files are kept under `.deps/b1gzip-ziparchive/`.

For PHP 8.2:

```sh
phpize8.2
CXX=g++ ./configure --with-php-config=/usr/bin/php-config8.2 --with-b1gzip
make -j"$(nproc)" CXX=g++
sudo make install
```

The automatic dependency build uses the Artpol source at <https://www.artpol-software.com/Downloads/ziparchive_src.zip> and these CMake options:

```sh
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
-DZIP_ENABLE_UNICODE=ON \
-DZIP_ENABLE_ZIP64=ON
```

To build using an already extracted ZipArchive source tree instead of downloading it, pass its path to `--with-b1gzip`:

```sh
CXX=g++ ./configure --with-php-config=/usr/bin/php-config8.2 --with-b1gzip=/path/to/ZipArchive
```

The directory can contain the project root or a parent directory beneath which the CMake project is located. The build helper locates `CMakeLists.txt`, `ZipArchive.h`, and the generated `libZipArchive.a` automatically.

If `phpize` has already been run for another PHP version, run `phpize --clean` before regenerating the build files. Enable the installed extension in the configuration for that same PHP installation:

```ini
extension=b1gzip.so
```

Verify the module loads with:

```sh
php --ri b1gzip
```

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
