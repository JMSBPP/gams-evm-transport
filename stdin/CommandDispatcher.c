#include <stdlib.h>

#define EXTRFUNC_API __attribute__((__visibility__("default")))

enum {
    EXTRFUNC_QUERYRETURN_ERROR = 0,
    EXTRFUNC_QUERYRETURN_OK = 1
};

enum {
    EXTRFUNC_LIBQUERY_API = 0,
    EXTRFUNC_LIBQUERY_LIBRARY = 1,
    EXTRFUNC_LIBQUERY_NFUNCTIONS = 2,
    EXTRFUNC_LIBQUERY_NEEDLICENSE = 3
};

EXTRFUNC_API void xcreate(void **data)
{
    if (data)
        *data = 0;
}

EXTRFUNC_API void xfree(void **data)
{
    if (data)
        *data = 0;
}

EXTRFUNC_API int libinit(void *data, int version, char *msg)
{
    (void)data;
    (void)version;
    (void)msg;
    return 0;
}

/* GAMS calls querylibrary. Ping.idr does the work. */
static void run_ping(void)
{
    static int started = 0;
    if (started)
        return;
    started = 1;
    system("idris2 --source-dir src -q -x ping src/Ping.idr");
}

EXTRFUNC_API int querylibrary(int funcnr, int query, int *iv, const char **pv)
{
    run_ping();
    *iv = -1;
    *pv = "Bad parameter(s)";
    if (funcnr > 0)
        return EXTRFUNC_QUERYRETURN_ERROR;
    switch (query) {
    case EXTRFUNC_LIBQUERY_API:
        *iv = 2;
        *pv = 0;
        break;
    case EXTRFUNC_LIBQUERY_LIBRARY:
        *iv = 1;
        *pv = "StdFetcherCommandList";
        break;
    case EXTRFUNC_LIBQUERY_NFUNCTIONS:
        *iv = 0;
        *pv = "Ping";
        break;
    case EXTRFUNC_LIBQUERY_NEEDLICENSE:
        *iv = 0;
        *pv = 0;
        break;
    default:
        return EXTRFUNC_QUERYRETURN_ERROR;
    }
    return EXTRFUNC_QUERYRETURN_OK;
}
