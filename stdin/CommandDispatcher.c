#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>

#include "extrfunc.h"

struct EXTRFUNC_Data {
    int unused;
};

/* GAMS calls querylibrary. Ping.idr does the work. */
static void run_ping(void)
{
    static int started = 0;
    if (started)
        return;
    started = 1;
    system("idris2 --source-dir src -q -x ping src/Ping.idr");
}

EXTRFUNC_API void EXTRFUNC_CALLCONV xcreate(EXTRFUNC_DATA **data)
{
    if (!data)
        return;
    *data = malloc(sizeof(EXTRFUNC_DATA));
    if (*data)
        (*data)->unused = 0;
}

EXTRFUNC_API void EXTRFUNC_CALLCONV xfree(EXTRFUNC_DATA **data)
{
    if (!data || !*data)
        return;
    free(*data);
    *data = NULL;
}

EXTRFUNC_API int EXTRFUNC_CALLCONV libinit(EXTRFUNC_DATA *data, int version, char *msg)
{
    (void)data;
    (void)version;
    (void)msg;
    return 0;
}

EXTRFUNC_API int EXTRFUNC_CALLCONV querylibrary(int funcnr, int query, int *iv, const char **pv)
{
    run_ping();
    *iv = -1;
    *pv = "Bad parameter(s)";

    if (funcnr <= 0) {
        switch ((EXTRFUNC_LIBQUERY)query) {
        case EXTRFUNC_LIBQUERY_API:
            *iv = 2;
            *pv = NULL;
            break;
        case EXTRFUNC_LIBQUERY_LIBRARY:
            *iv = 1;
            *pv = "StdFetcherCommandList";
            break;
        case EXTRFUNC_LIBQUERY_NFUNCTIONS:
            *iv = 1;
            *pv = "StdFetcherCommandList extrinsic library";
            break;
        case EXTRFUNC_LIBQUERY_NEEDLICENSE:
            *iv = 0;
            *pv = NULL;
            break;
        default:
            return EXTRFUNC_QUERYRETURN_ERROR;
        }
        return EXTRFUNC_QUERYRETURN_OK;
    }

    if (funcnr != 1)
        return EXTRFUNC_QUERYRETURN_ERROR;

    switch ((EXTRFUNC_FUNCQUERY)query) {
    case EXTRFUNC_FUNCQUERY_FUNCNAME:
        *iv = 0;
        *pv = "broadcast_tick_path";
        break;
    case EXTRFUNC_FUNCQUERY_FUNCDESCR:
        *iv = 0;
        *pv = "Broadcast GDX Tick path from build/.gdx-publish-path; block until consumed";
        break;
    case EXTRFUNC_FUNCQUERY_NOTINEQU:
        *iv = 1;
        *pv = NULL;
        break;
    case EXTRFUNC_FUNCQUERY_CONTINDERIV:
        *iv = 0;
        *pv = NULL;
        break;
    case EXTRFUNC_FUNCQUERY_ZERORIPPLE:
        *iv = 0;
        *pv = NULL;
        break;
    case EXTRFUNC_FUNCQUERY_ARGMIN:
        *iv = 0;
        *pv = NULL;
        break;
    case EXTRFUNC_FUNCQUERY_ARGMAX:
        *iv = 0;
        *pv = NULL;
        break;
    case EXTRFUNC_FUNCQUERY_MAXDERIV:
        *iv = 0;
        *pv = NULL;
        break;
    default:
        return EXTRFUNC_QUERYRETURN_ERROR;
    }
    return EXTRFUNC_QUERYRETURN_OK;
}

EXTRFUNC_DECL_FUNCCALL(broadcast_tick_path)
{
    char msg[EXTRFUNC_STRSIZE];
    int st;
    int code;

    (void)data;
    (void)derivrequest;
    (void)x;
    (void)gradient;
    (void)hessian;

    if (nargs != 0) {
        sprintf(msg + 1, "broadcast_tick_path: zero arguments expected. Called with %d", nargs);
        msg[0] = (char)strlen(msg + 1);
        return errorcallback(EXTRFUNC_RETURN_FUNCTION, EXTRFUNC_EVALERROR_DOMAIN, msg, errorcbmem);
    }

    st = system("just broadcast_tick_path");
    if (st == -1) {
        sprintf(msg + 1, "broadcast_tick_path: failed to invoke just broadcast_tick_path");
        msg[0] = (char)strlen(msg + 1);
        return errorcallback(EXTRFUNC_RETURN_SYSTEM, EXTRFUNC_EVALERROR_NONE, msg, errorcbmem);
    }

    if (WIFEXITED(st))
        code = WEXITSTATUS(st);
    else
        code = 1;

    *funcvalue = (double)code;
    return EXTRFUNC_RETURN_OK;
}
