/*
  +----------------------------------------------------------------------+
  | b1gZIP PHP 8 extension                                              |
  +----------------------------------------------------------------------+
*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

extern "C" {
#include "php.h"
#include "php_ini.h"
#include "ext/standard/info.h"
}

#include "php_b1gzip.h"
#include <ZipArchive.h>
#include <exception>
#include <new>

static int le_b1gzip;

struct zip_res {
    CZipArchive zip;
    CZipMemFile out;
    bool opened;
    bool finalized;

    zip_res() : opened(false), finalized(false) {}
};

ZEND_BEGIN_ARG_INFO_EX(arginfo_b1gzip_create, 0, 0, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_b1gzip_add, 0, 0, 3)
    ZEND_ARG_INFO(0, resource)
    ZEND_ARG_INFO(0, data)
    ZEND_ARG_INFO(0, filename)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_b1gzip_final, 0, 0, 1)
    ZEND_ARG_INFO(0, resource)
ZEND_END_ARG_INFO()

static const zend_function_entry b1gzip_functions[] = {
    PHP_FE(b1gzip_create, arginfo_b1gzip_create)
    PHP_FE(b1gzip_add, arginfo_b1gzip_add)
    PHP_FE(b1gzip_final, arginfo_b1gzip_final)
    PHP_FE_END
};

zend_module_entry b1gzip_module_entry = {
    STANDARD_MODULE_HEADER,
    "b1gzip",
    b1gzip_functions,
    PHP_MINIT(b1gzip),
    PHP_MSHUTDOWN(b1gzip),
    PHP_RINIT(b1gzip),
    PHP_RSHUTDOWN(b1gzip),
    PHP_MINFO(b1gzip),
    "0.2.0",
    STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_B1GZIP
extern "C" {
ZEND_GET_MODULE(b1gzip)
}
#endif

static void zip_res_dtor(zend_resource *rsrc)
{
    zip_res *handle = static_cast<zip_res *>(rsrc->ptr);
    if (handle == NULL) {
        return;
    }

    // Destructors must not allow C++ exceptions to escape into the Zend Engine.
    if (handle->opened && !handle->finalized) {
        try {
            handle->zip.Close();
        } catch (...) {
            /* There is no safe recovery path during resource destruction. */
        }
    }
    delete handle;
}

PHP_MINIT_FUNCTION(b1gzip)
{
    le_b1gzip = zend_register_list_destructors_ex(zip_res_dtor, NULL, "b1gzip resource", module_number);
    return SUCCESS;
}

PHP_MSHUTDOWN_FUNCTION(b1gzip)
{
    return SUCCESS;
}

PHP_RINIT_FUNCTION(b1gzip)
{
#if defined(ZTS) && defined(COMPILE_DL_B1GZIP)
    ZEND_TSRMLS_CACHE_UPDATE();
#endif
    return SUCCESS;
}

PHP_RSHUTDOWN_FUNCTION(b1gzip)
{
    return SUCCESS;
}

PHP_MINFO_FUNCTION(b1gzip)
{
    php_info_print_table_start();
    php_info_print_table_header(2, "b1gzip support", "enabled");
    php_info_print_table_row(2, "version", "0.2.0");
    php_info_print_table_end();
}

PHP_FUNCTION(b1gzip_create)
{
    zip_res *handle = NULL;

    try {
        handle = new (std::nothrow) zip_res;
        if (handle == NULL) {
            zend_throw_error(NULL, "Unable to allocate b1gzip resource");
            return;
        }

        handle->zip.Open(handle->out, CZipArchive::zipCreate);
        handle->opened = true;
        RETURN_RES(zend_register_resource(handle, le_b1gzip));
    } catch (const std::exception &exception) {
        delete handle;
        zend_throw_error(NULL, "Unable to create b1gzip archive: %s", exception.what());
    } catch (...) {
        delete handle;
        zend_throw_error(NULL, "Unable to create b1gzip archive");
    }
}

PHP_FUNCTION(b1gzip_add)
{
    zval *resource = NULL;
    zend_string *data = NULL;
    zend_string *filename = NULL;
    zip_res *handle = NULL;

    if (zend_parse_parameters(ZEND_NUM_ARGS(), "rSS", &resource, &data, &filename) == FAILURE) {
        return;
    }

    handle = static_cast<zip_res *>(zend_fetch_resource(Z_RES_P(resource), "b1gzip resource", le_b1gzip));
    if (handle == NULL) {
        zend_throw_error(NULL, "Invalid or closed b1gzip resource");
        return;
    }
    if (handle->finalized) {
        zend_throw_error(NULL, "Cannot add files to a finalized b1gzip archive");
        return;
    }

    try {
        CZipMemFile newfile;
        newfile.Attach(reinterpret_cast<BYTE *>(ZSTR_VAL(data)), ZSTR_LEN(data));
        handle->zip.AddNewFile(newfile, ZSTR_VAL(filename));
    } catch (const std::exception &exception) {
        zend_throw_error(NULL, "Unable to add file to b1gzip archive: %s", exception.what());
    } catch (...) {
        zend_throw_error(NULL, "Unable to add file to b1gzip archive");
    }
}

PHP_FUNCTION(b1gzip_final)
{
    zval *resource = NULL;
    zip_res *handle = NULL;
    size_t zip_len = 0;
    char *zip_data = NULL;

    if (zend_parse_parameters(ZEND_NUM_ARGS(), "r", &resource) == FAILURE) {
        return;
    }

    handle = static_cast<zip_res *>(zend_fetch_resource(Z_RES_P(resource), "b1gzip resource", le_b1gzip));
    if (handle == NULL) {
        zend_throw_error(NULL, "Invalid or closed b1gzip resource");
        return;
    }
    if (handle->finalized) {
        zend_throw_error(NULL, "b1gzip archive has already been finalized");
        return;
    }

    try {
        handle->zip.Close();
        handle->finalized = true;
        zip_len = handle->out.GetLength();
        zip_data = reinterpret_cast<char *>(handle->out.Detach());
    } catch (const std::exception &exception) {
        zend_throw_error(NULL, "Unable to finalize b1gzip archive: %s", exception.what());
        return;
    } catch (...) {
        zend_throw_error(NULL, "Unable to finalize b1gzip archive");
        return;
    }

    // RETURN_STRINGL copies the detached buffer into a PHP-managed string.
    zend_list_delete(Z_RES_P(resource));
    RETURN_STRINGL(zip_data, zip_len);
}
