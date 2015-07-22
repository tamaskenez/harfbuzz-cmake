cmake_minimum_required(VERSION 3.1) # FindThreads Threads::Threads
project(harfbuzz)

# build ragel
find_package(ragel QUIET)
if(NOT ragel_FOUND)
    include(cmake/CloneAndInstall.cmake)
    clone_and_install(ragel
        GIT_URL "https://github.com/tamaskenez/ragel-cmake.git"
        CONFIGURATION_TYPES Release)
    find_package(ragel REQUIRED)
endif()

set(CMAKE_DEBUG_POSTFIX _d)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)

if(MSVC)
    add_definitions(/wd4996 /wd4800)
endif()

include(CMakePrintHelpers)

set(start_bracket "\\[")
set(start_paren "\\(")
set(no_end_bracket "[^]]")
set(no_start_bracket "[^[]")
file(STRINGS configure.ac configure.ac)
string(CONCAT ac_init_regex
    "AC_INIT${start_paren}${start_bracket}(${no_end_bracket}*)]${no_start_bracket}*" # AC_INIT([HarfBuzz],
    "${start_bracket}(${no_end_bracket}*)]${no_start_bracket}*" # [0.9.41],
    "${start_bracket}(${no_end_bracket}*)]${no_start_bracket}*" # [http://bugs.freedesktop.org/enter_bug.cgi?product=harfbuzz],
    "${start_bracket}(${no_end_bracket}*)]${no_start_bracket}*" # [harfbuzz],
    "${start_bracket}(${no_end_bracket}*)]${no_start_bracket}*\\)" # [http://harfbuzz.org/])
    )
string(REGEX MATCH "${ac_init_regex}" _ "${configure.ac}")

set(PACKAGE "${CMAKE_MATCH_4}")
set(PACKAGE_NAME "${CMAKE_MATCH_1}")
set(PACKAGE_VERSION "${CMAKE_MATCH_2}")
set(PACKAGE_BUGREPORT "${CMAKE_MATCH_3}")

if(NOT PACKAGE OR NOT PACKAGE_NAME OR NOT PACKAGE_BUGREPORT OR NOT PACKAGE_VERSION)
    message(FATAL_ERROR "Can't parse AC_INIT from configure.ac, check file and regexes.")
endif()

set(HB_VERSION "${PACKAGE_VERSION}")
string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)$" _ "${PACKAGE_VERSION}")
set(HB_VERSION_MAJOR "${CMAKE_MATCH_1}")
set(HB_VERSION_MINOR "${CMAKE_MATCH_2}")
set(HB_VERSION_MICRO "${CMAKE_MATCH_3}")

math(EXPR HB_VERSION_INT "${HB_VERSION_MAJOR}*10000 + ${HB_VERSION_MINOR}*100 + ${HB_VERSION_MICRO}")
math(EXPR HB_VERSION_MINOR_MOD_2 "${HB_VERSION_MINOR} % 2")
if(HB_VERSION_MINOR_MOD_2 EQUAL 1)
	set(HB_LIBTOOL_REVISION 0)
else()
	set(HB_LIBTOOL_REVISION "${HB_VERSION_MICRO}")
endif()

math(EXPR HB_LIBTOOL_AGE "${HB_VERSION_INT} - ${HB_LIBTOOL_REVISION}")
math(EXPR HB_LIBTOOL_CURRENT "${HB_VERSION_MAJOR} + ${HB_LIBTOOL_AGE}")
set(HB_LIBTOOL_VERSION_INFO ${HB_LIBTOOL_CURRENT}.${HB_LIBTOOL_REVISION}.${HB_LIBTOOL_AGE})

include(CheckFunctionExists)
include(CheckSymbolExists)
check_symbol_exists(atexit stdlib.h HAVE_ATEXIT)
check_symbol_exists(mprotect sys/mman.h HAVE_MPROTEXT)
check_symbol_exists(sysconf unistd.h HAVE_SYSCONF)
check_symbol_exists(getpagesize unistd.h HAVE_GETPAGESIZE)
check_symbol_exists(mmap sys/mman.h HAVE_MMAP)
check_symbol_exists(isatty unistd.h HAVE_ISATTY)

include(CheckIncludeFile)
check_include_file(unistd.h HAVE_UNISTD_H)
check_include_file(sys/mman.h HAVE_SYS_MMAN_H)

# these flags could be set for gcc:
#	LDFLAGS="$LDFLAGS -Bsymbolic-functions"
#	CXXFLAGS="$CXXFLAGS -fno-rtti -fno-exceptions"
#	CXXFLAGS="$CXXFLAGS -Wcast-align"

# for arm keep exact struct size:
#			if test "x$ac_cv_alignof_struct_char__" != x1; then
#				# Request byte alignment
#				CXXFLAGS="$CXXFLAGS -mstructure-size-boundary=8"
#			fi

if(CMAKE_COMPILER_IS_GNUCC)
	set(HAVE_GCC 1)
endif()
if(WIN32)
	set(OS_WIN32 1)
endif()

set(CMAKE_THREAD_PREFER_PTHREAD 1)
set(THREADS_PREFER_PTHREAD_FLAG 1)
include(FindThreads)
set(HAVE_PTHREAD "${CMAKE_USE_PTHREADS_INIT}")

set(HAVE_OT 1) # Have native OpenType Layout backend
set(HAVE_FALLBACK 1) # Have simple TrueType Layout backend])
set(HAVE_GLIB 0) # --with-glib
set(HAVE_GOBJECT 0) # --with-gobject
#	GLIB_MKENUMS=`$PKG_CONFIG --variable=glib_mkenums glib-2.0`
set(HAVE_INTROSPECTION 0)

set(HAVE_UCDN 1) # Have UCDN Unicode functions
if(HAVE_GLIB)
	set(HAVE_UCDN 0)
endif()

set(HAVE_CAIRO 0) # --with-cairo
set(HAVE_CAIRO_FT 0) # cairo-ft
set(HAVE_FONTCONFIG 0) # --with-fontconfig
set(HAVE_ICU 0) # --with-icu
set(HAVE_GRAPHITE2 0) # --with-graphite2
set(HAVE_FREETYPE 0) # --with-freetype
set(HAVE_UNISCRIBE 0) # --with-uniscribe
set(HAVE_CORETEXT 0) # --with-coretext

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/try_compile_intel_atomic_primitives.c"
"		void memory_barrier (void) { __sync_synchronize (); }
		int atomic_add (int *i) { return __sync_fetch_and_add (i, 1); }
		int mutex_trylock (int *m) { return __sync_lock_test_and_set (m, 1); }
		void mutex_unlock (int *m) { __sync_lock_release (m); }
")
try_compile(HAVE_INTEL_ATOMIC_PRIMITIVES
	${CMAKE_CURRENT_BINARY_DIR}/try_compile_intel_atomic_primitives
	SOURCES ${CMAKE_CURRENT_BINARY_DIR}/try_compile_intel_atomic_primitives.c)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/try_compile_solaris_atomic_ops.c"
"		#include <atomic.h>
		/* This requires Solaris Studio 12.2 or newer: */
		#include <mbarrier.h>
		void memory_barrier (void) { __machine_rw_barrier (); }
		int atomic_add (volatile unsigned *i) { return atomic_add_int_nv (i, 1); }
		void *atomic_ptr_cmpxchg (volatile void **target, void *cmp, void *newval) { return atomic_cas_ptr (target, cmp, newval); }
")
try_compile(HAVE_SOLARIS_ATOMIC_OPS
	${CMAKE_CURRENT_BINARY_DIR}/try_compile_solaris_atomic_ops
	SOURCES ${CMAKE_CURRENT_BINARY_DIR}/try_compile_solaris_atomic_ops.c)

include(CheckLibraryExists)
if(NOT WIN32 AND NOT HAVE_PTHREAD)
	check_include_file(sched.h HAVE_SCHED_H)
	check_library_exists(rt sched_yield "" HAVE_SCHED_YIELD)
endif()

configure_file(src/hb-version.h.in hb-version.h @ONLY)
configure_file(cmake/config.h.in config.h @ONLY)
add_definitions(-DHAVE_CONFIG_H)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

foreach(sd src test)# util)
	add_subdirectory(${sd})
endforeach()

