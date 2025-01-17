/*
  +----------------------------------------------------------------------+
  | PHP Version 7                                                        |
  +----------------------------------------------------------------------+
  | Copyright (c) 1997-2013 The PHP Group                                |
  +----------------------------------------------------------------------+
  | http://www.opensource.org/licenses/mit-license.php  MIT License      |
  +----------------------------------------------------------------------+
  | Author: Jani Taskinen <jani.taskinen@iki.fi>                         |
  | Author: Patrick Reilly <preilly@php.net>                             |
  +----------------------------------------------------------------------+
*/

#ifndef V8JS_V8_H
#define V8JS_V8_H

#include <functional>

/* Helper macros */
#define V8JS_SYM(v)			(v8::String::NewFromUtf8(isolate, v, v8::NewStringType::kInternalized, sizeof(v) - 1).ToLocalChecked())
#define V8JS_SYML(v, l)		(v8::String::NewFromUtf8(isolate, v, v8::NewStringType::kInternalized, l).ToLocalChecked())
#define V8JS_ZSYM(v)		(v8::String::NewFromUtf8(isolate, ZSTR_VAL(v), v8::NewStringType::kInternalized, ZSTR_LEN(v)).ToLocalChecked())
#define V8JS_STR(v)			(v8::String::NewFromUtf8(isolate, v, v8::NewStringType::kNormal).ToLocalChecked())
#define V8JS_STRL(v, l)		(v8::String::NewFromUtf8(isolate, v, v8::NewStringType::kNormal, l).ToLocalChecked())
#define V8JS_ZSTR(v)		(v8::String::NewFromUtf8(isolate, ZSTR_VAL(v), v8::NewStringType::kNormal, ZSTR_LEN(v)).ToLocalChecked())
#define V8JS_INT(v)			v8::Integer::New(isolate, v)
#define V8JS_UINT(v)		v8::Integer::NewFromUnsigned(isolate, v)
#define V8JS_FLOAT(v)		v8::Number::New(isolate, v)
#define V8JS_BOOL(v)		((v)?v8::True(isolate):v8::False(isolate))
#define V8JS_TRUE()			v8::True(isolate)
#define V8JS_FALSE()		v8::False(isolate)
#define V8JS_NULL			v8::Null(isolate)
#define V8JS_UNDEFINED		v8::Undefined(isolate)
#define V8JS_MN(name)		v8js_method_##name
#define V8JS_METHOD(name)	void V8JS_MN(name)(const v8::FunctionCallbackInfo<v8::Value>& info)
#define V8JS_THROW(isolate, type, message, message_len)	(isolate)->ThrowException(v8::Exception::type(V8JS_STRL(message, message_len)))
#define V8JS_GLOBAL(isolate)			((isolate)->GetCurrentContext()->Global())


/* On Windows there are max and min macros, which would clobber the
 * method names of std::numeric_limits< > otherwise. */
#undef max
#undef min


/* Extracts a C string from a V8 Utf8Value. */
static inline const char * ToCString(const v8::String::Utf8Value &value) /* {{{ */
{
	return *value ? *value : "<string conversion failed>";
}
/* }}} */



void v8js_v8_init();
void v8js_v8_call(v8js_ctx *c, zval **return_value,
				  long flags, long time_limit, size_t memory_limit,
				  std::function< v8::MaybeLocal<v8::Value>(v8::Isolate *) >& v8_call);
void v8js_terminate_execution(v8::Isolate *isolate);

/* Fetch V8 object properties */
int v8js_get_properties_hash(v8::Local<v8::Value> jsValue, HashTable *retval, int flags, v8::Isolate *isolate);

#define V8JS_CTX_PROLOGUE_EX(ctx, ret) \
	if (!V8JSG(v8_initialized)) { \
		zend_error(E_ERROR, "V8 not initialized"); \
		return ret; \
	} \
	\
	v8::Isolate *isolate = (ctx)->isolate; \
	v8::Locker locker(isolate); \
	v8::Isolate::Scope isolate_scope(isolate); \
	v8::HandleScope handle_scope(isolate); \
	v8::Local<v8::Context> v8_context = v8::Local<v8::Context>::New(isolate, (ctx)->context); \
	v8::Context::Scope context_scope(v8_context);

#define V8JS_CTX_PROLOGUE(ctx) \
	V8JS_CTX_PROLOGUE_EX(ctx,)

#define V8JS_BEGIN_CTX(ctx, object) \
	v8js_ctx *(ctx); \
	(ctx) = Z_V8JS_CTX_OBJ_P(object); \
	V8JS_CTX_PROLOGUE(ctx);

#define V8JS_BEGIN_CTX_OBJ(ctx, object) \
	v8js_ctx *(ctx); \
	(ctx) = Z_V8JS_CTX_OBJ(object); \
	V8JS_CTX_PROLOGUE(ctx);


// In PHP 8.1, mismatched tentative return types emit a deprecation notice.
// https://wiki.php.net/rfc/internal_method_return_types
//
// When compiling for earlier php versions, the return type is dropped.
#if PHP_VERSION_ID < 80100
#define ZEND_BEGIN_ARG_WITH_TENTATIVE_RETURN_TYPE_INFO_EX(name, return_reference, required_num_args, type, allow_null) \
        ZEND_BEGIN_ARG_INFO_EX(name, return_reference, required_num_args, allow_null)
#endif

#ifndef IS_VOID
#define IS_VOID 99
#endif

#ifndef IS_MIXED
#define IS_MIXED 99
#endif

#ifndef _IS_BOOL
#define _IS_BOOL 99
#endif

#ifndef IS_LONG
#define IS_LONG 99
#endif

#define PHP_V8_HAS_INTERCEPTED PHP_V8_API_VERSION >= 12005000

#if PHP_V8_HAS_INTERCEPTED
#define V8JS_INTERCEPTED			v8::Intercepted
#define V8JS_INTERCEPTED_YES		v8::Intercepted::kYes
#define V8JS_INTERCEPTED_NO			v8::Intercepted::kNo
#define V8JS_SETTER_PROPERTY_CALLBACK_INFO	v8::PropertyCallbackInfo<void>

#else
#define V8JS_INTERCEPTED			void
#define V8JS_INTERCEPTED_YES
#define V8JS_INTERCEPTED_NO
#define V8JS_SETTER_PROPERTY_CALLBACK_INFO	v8::PropertyCallbackInfo<v8::Value>

#endif


#endif /* V8JS_V8_H */

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
