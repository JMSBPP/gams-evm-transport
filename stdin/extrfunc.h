/* GAMS Extrinsic Functions C API */

#ifndef EXTRFUNC_H_
#define EXTRFUNC_H_

#if defined(_WIN32)
# define EXTRFUNC_API __declspec(dllexport)
#elif defined(__GNUC__)
# define EXTRFUNC_API __attribute__((__visibility__("default")))
#else
# define EXTRFUNC_API
#endif

/* deprecated */
#define EXTRFUNC_CALLCONV

#define EXTRFUNC_STRSIZE 257

/** Extrinsic Function Data Structure */
struct EXTRFUNC_Data;
/** Extrinsic Function Data Type */
typedef struct EXTRFUNC_Data EXTRFUNC_DATA;

/** Return codes for function calls */
typedef enum
{
   EXTRFUNC_RETURN_OK       = 0,  /**< no error */
   EXTRFUNC_RETURN_FUNCTION = 1,  /**< error during function evaluation */
   EXTRFUNC_RETURN_GRADIENT = 2,  /**< error during gradient evaluation */
   EXTRFUNC_RETURN_HESSIAN  = 3,  /**< error during Hessian evaluation */
   EXTRFUNC_RETURN_SYSTEM   = 4   /**< system error */
} EXTRFUNC_RETURN;

/** Evaluation error codes.
 *
 * In case of a numerical failure evaluating the function (e.g., a
 * floating point exception), this code specifies closer the source of
 * the failure. Codes other than EXTRFUNC_EVALERROR_NONE have to be
 * used in connection with the return codes EXTRFUNC_RETURN_FUNCTION,
 * EXTRFUNC_RETURN_GRADIENT, and EXTRFUNC_RETURN_HESSIAN. The code
 * EXTRFUNC_EVALERROR_NONE can only be used in connection with the
 * return code EXTRFUNC_RETURN_SYSTEM, i.e., in cases where a
 * "structural error" occurs (e.g., call with wrong number of argument,
 * requested derivative not available, ...).
 */
typedef enum
{
   EXTRFUNC_EVALERROR_NONE        = 0, /**< there was no eval error */
   EXTRFUNC_EVALERROR_DOMAIN      = 1, /**< domain violation (function cannot be evaluated at given point) */
   EXTRFUNC_EVALERROR_SINGULAR    = 2, /**< singular point (1st or 2nd derivative cannot be evaluated at given point) */
   EXTRFUNC_EVALERROR_OVERFLOW    = 3, /**< float point value overflow */
   EXTRFUNC_EVALERROR_SIGLOSS     = 4  /**< loss of significance */
} EXTRFUNC_EVALERROR;

/* deprecated names for function evaluation codes */
#define EXTRFUNC_ERROR             EXTRFUNC_EVALERROR
#define EXTRFUNC_ERROR_UNSPECIFIED EXTRFUNC_EVALERROR_NONE
#define EXTRFUNC_ERROR_DOMAIN      EXTRFUNC_EVALERROR_DOMAIN
#define EXTRFUNC_ERROR_SINGULAR    EXTRFUNC_EVALERROR_SINGULAR
#define EXTRFUNC_ERROR_OVERFLOW    EXTRFUNC_EVALERROR_OVERFLOW
#define EXTRFUNC_ERROR_SIGLOSS     EXTRFUNC_EVALERROR_SIGLOSS

/** Return codes for query function */
typedef enum
{
   EXTRFUNC_QUERYRETURN_ERROR = 0, /**< error */
   EXTRFUNC_QUERYRETURN_OK    = 1  /**< no error */
} EXTRFUNC_QUERYRETURN;

/** Library query codes */
typedef enum
{
   EXTRFUNC_LIBQUERY_API        = 0, /**< query for API version */
   EXTRFUNC_LIBQUERY_LIBRARY    = 1, /**< query for library version and vendor */
   EXTRFUNC_LIBQUERY_NFUNCTIONS = 2, /**< query for number of functions and library description */
   EXTRFUNC_LIBQUERY_NEEDLICENSE= 3  /**< query whether library requires license checking */
} EXTRFUNC_LIBQUERY;

/** Function query codes */
typedef enum
{
   EXTRFUNC_FUNCQUERY_FUNCNAME   = 1, /**< query for function name */
   EXTRFUNC_FUNCQUERY_FUNCDESCR  = 2, /**< query for function description */
   EXTRFUNC_FUNCQUERY_NOTINEQU   = 3, /**< query whether function can not be used in a GAMS equation */
   EXTRFUNC_FUNCQUERY_CONTINDERIV = 4, /**< query whether function has a continuous derivative */
   EXTRFUNC_FUNCQUERY_ZERORIPPLE = 5, /**< query whether function is 0 at origin */
   EXTRFUNC_FUNCQUERY_ARGMIN     = 6, /**< query for minimal number of arguments */
   EXTRFUNC_FUNCQUERY_ARGMAX     = 7, /**< query for maximal number of arguments */
   EXTRFUNC_FUNCQUERY_MAXDERIV   = 8, /**< query for highest derivative that can be computed for this function */
   EXTRFUNC_FUNCQUERY_ARG01      = 1001, /**< query function argument 1  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG02      = 1002, /**< query function argument 2  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG03      = 1003, /**< query function argument 3  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG04      = 1004, /**< query function argument 4  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG05      = 1005, /**< query function argument 5  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG06      = 1006, /**< query function argument 6  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG07      = 1007, /**< query function argument 7  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG08      = 1008, /**< query function argument 8  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG09      = 1009, /**< query function argument 9  (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG10      = 1010, /**< query function argument 10 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG11      = 1011, /**< query function argument 11 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG12      = 1012, /**< query function argument 12 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG13      = 1013, /**< query function argument 13 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG14      = 1014, /**< query function argument 14 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG15      = 1015, /**< query function argument 15 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG16      = 1016, /**< query function argument 16 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG17      = 1017, /**< query function argument 17 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG18      = 1018, /**< query function argument 18 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG19      = 1019, /**< query function argument 19 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
   EXTRFUNC_FUNCQUERY_ARG20      = 1020  /**< query function argument 20 (iv = 1 if endogenuos, 0 otherwise; pv = argument name) */
} EXTRFUNC_FUNCQUERY;

/** Error callback signature */
typedef EXTRFUNC_RETURN (*extrfuncLogError_t) (
   EXTRFUNC_RETURN       retCode,            /**< return code */
   EXTRFUNC_EVALERROR    excCode,            /**< additional info in case of an evaluation error */
   char*                 msg,                /**< error message */
   void*                 usrmem              /**< error callback user memory */
   );

#if defined(__cplusplus)
#define EXTRFUNC_DECL_EXTERNC extern "C"
#else
#define EXTRFUNC_DECL_EXTERNC
#endif

/** Macro to declare extrinsic function callback
 *
 * - derivrequest  (in)  : 0 when only function value is requested;
 *                         1 when function value and gradient is requested;
 *                         2 when function value, gradient, and Hessian is requested
 * - nargs         (in)  : number of given function arguments
 * - x             (in)  : array of length nargs specifying function arguments
 * - funcvalue     (out) : buffer to store function value
 * - gradient      (out) : array of length nargs to store gradient values
 * - hessian       (out) : array of length nargs*nargs to store full Hessian in dense form
 * - errorcallback (in)  : callback function for printing error messages
 * - errorcbmem    (in)  : error callback memory to pass to callback function
 */
#define EXTRFUNC_DECL_FUNCCALL(f) EXTRFUNC_DECL_EXTERNC EXTRFUNC_API EXTRFUNC_RETURN f( \
   EXTRFUNC_DATA*        data,          \
   int                   derivrequest,  \
   int                   nargs,         \
   double                x[],           \
   double*               funcvalue,     \
   double                gradient[],    \
   double                hessian[],     \
   extrfuncLogError_t    errorcallback, \
   void*                 errorcbmem     \
   )

#if defined(__cplusplus)
extern "C" {
#endif

/** Callback function to create function library data.
 *
 * This function is called by the GAMS execution system after the library
 * has been loaded. Its purpose is to allocate and initialize the
 * library-specific data structure (struct EXTRFUNC_Data).
 */
EXTRFUNC_API void xcreate(
   EXTRFUNC_DATA**       data             /**< buffer to store pointer to function library data structure */
   );

/** Callback function to free function library data.
 *
 * This function is called by the GAMS execution system before the library
 * is unloaded. Its purpose is to free the library-specific data.
 */
EXTRFUNC_API void xfree(
   EXTRFUNC_DATA**       data             /**< pointer to pointer to function library data structure */
   );

/** Callback function to initialize function library.
 *
 * This function is called by the GAMS execution system after the library
 * has been loaded and library-specific data has been initialized.
 *
 * Its purpose is to check whether the API version of the library
 * is compatible with the GAMS execution system.
 * Additionally, library-specific initializations can be executed in this
 * call.
 *
 * In difference to xcreate, this function can return a message
 * and error code to the GAMS execution system in case of an error.
 *
 * @return 0 if successful, <> 0 in case of error.
 */
EXTRFUNC_API int libinit(
   EXTRFUNC_DATA*        data,            /**< function library data structure */
   int                   version,         /**< version number */
   char*                 msg              /**< buffer of length 255 to store error message (as Delphi string!) */
   );

/** Callback function to query function library functionality */
EXTRFUNC_API int querylibrary(
   int                   funcnr,          /**< function number, or <= 0 for library query */
   int                   query,           /**< query number (either EXTRFUNC_LIBQUERY or EXTRFUNC_FUNCQUERY) */
   int*                  iv,              /**< buffer to store integer result */
   const char**          pv               /**< buffer to store string result (as C string!) */
   );

#if defined(__cplusplus)
}
#endif

#endif /* EXTRFUNC_H_ */
