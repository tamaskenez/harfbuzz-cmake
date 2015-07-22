set(HBSOURCES
    hb-atomic-private.hh
    hb-blob.cc
    hb-buffer-deserialize-json.hh
    hb-buffer-deserialize-text.hh
    hb-buffer-private.hh
    hb-buffer-serialize.cc
    hb-buffer.cc
    hb-cache-private.hh
    hb-common.cc
    hb-face-private.hh
    hb-face.cc
    hb-font-private.hh
    hb-font.cc
    hb-mutex-private.hh
    hb-object-private.hh
    hb-open-file-private.hh
    hb-open-type-private.hh
    hb-ot-cmap-table.hh
    hb-ot-head-table.hh
    hb-ot-hhea-table.hh
    hb-ot-hmtx-table.hh
    hb-ot-maxp-table.hh
    hb-ot-name-table.hh
    hb-ot-tag.cc
    hb-private.hh
    hb-set-private.hh
    hb-set.cc
    hb-shape.cc
    hb-shape-plan-private.hh
    hb-shape-plan.cc
    hb-shaper-list.hh
    hb-shaper-impl-private.hh
    hb-shaper-private.hh
    hb-shaper.cc
    hb-unicode-private.hh
    hb-unicode.cc
    hb-utf-private.hh
    hb-warning.cc)
set(HBHEADERS
    hb.h
    hb-blob.h
    hb-buffer.h
    hb-common.h
    hb-deprecated.h
    hb-face.h
    hb-font.h
    hb-set.h
    hb-shape.h
    hb-shape-plan.h
    hb-unicode.h)
set(HBNODISTHEADERS
    hb-version.h)

if(HAVE_OT)
    list(APPEND HBSOURCES
        hb-ot-font.cc
        hb-ot-layout.cc
        hb-ot-layout-common-private.hh
        hb-ot-layout-gdef-table.hh
        hb-ot-layout-gpos-table.hh
        hb-ot-layout-gsubgpos-private.hh
        hb-ot-layout-gsub-table.hh
        hb-ot-layout-jstf-table.hh
        hb-ot-layout-private.hh
        hb-ot-map.cc
        hb-ot-map-private.hh
        hb-ot-shape.cc
        hb-ot-shape-complex-arabic.cc
        hb-ot-shape-complex-arabic-fallback.hh
        hb-ot-shape-complex-arabic-table.hh
        hb-ot-shape-complex-arabic-win1256.hh
        hb-ot-shape-complex-default.cc
        hb-ot-shape-complex-hangul.cc
        hb-ot-shape-complex-hebrew.cc
        hb-ot-shape-complex-indic.cc
        hb-ot-shape-complex-indic-machine.hh
        hb-ot-shape-complex-indic-private.hh
        hb-ot-shape-complex-indic-table.cc
        hb-ot-shape-complex-myanmar.cc
        hb-ot-shape-complex-myanmar-machine.hh
        hb-ot-shape-complex-sea.cc
        hb-ot-shape-complex-sea-machine.hh
        hb-ot-shape-complex-thai.cc
        hb-ot-shape-complex-tibetan.cc
        hb-ot-shape-complex-private.hh
        hb-ot-shape-normalize-private.hh
        hb-ot-shape-normalize.cc
        hb-ot-shape-fallback-private.hh
        hb-ot-shape-fallback.cc
        hb-ot-shape-private.hh)
    list(APPEND HBHEADERS
        hb-ot.h
        hb-ot-font.h
        hb-ot-layout.h
        hb-ot-shape.h
        hb-ot-tag.h)
endif()

if(HAVE_FALLBACK)
    list(APPEND HBSOURCES hb-fallback-shape.cc)
endif()

set(public_deps "")
set(private_deps Threads::Threads)

if(HAVE_GLIB)
    list(APPEND private_deps glib)
    list(APPEND HBSOURCES hb-glib.cc)
    list(APPEND HBHEADERS hb-glib.h)
endif()

if(HAVE_FREETYPE)
    list(APPEND private_deps freetype)
    list(APPEND HBSOURCES hb-ft.cc)
    list(APPEND HBHEADERS hb-ft.h)
endif()

if(HAVE_GRAPHITE2)
    list(APPEND private_deps graphite2)    
    list(APPEND HBSOURCES hb-graphite2.cc)
    list(APPEND HBHEADERS hb-graphite2.h)
endif()

if(HAVE_UNISCRIBE)
    list(APPEND private_deps uniscribe)
    list(APPEND HBSOURCES hb-uniscribe.cc)
    list(APPEND HBHEADERS hb-uniscribe.h)
endif()

if(HAVE_CORETEXT)
    list(APPEND private_deps coretext)
    list(APPEND HBSOURCES hb-coretext.cc)
    list(APPEND HBHEADERS hb-coretext.h)
endif()

set(optional_ucnd_object_libs "")
set(libharfbuzz_include_dirs "")
if(HAVE_UCDN)
    add_subdirectory(hb-ucdn)
    set(optional_ucnd_object_libs $<TARGET_OBJECTS:libhb-ucdn>)
    list(APPEND HBSOURCES hb-ucdn.cc)
    list(APPEND libharfbuzz_include_dirs ${CMAKE_CURRENT_SOURCE_DIR}/hb-ucdn)
endif()

foreach(root
    hb-buffer-deserialize-json
    hb-buffer-deserialize-text
    hb-ot-shape-complex-indic-machine
    hb-ot-shape-complex-myanmar-machine
    hb-ot-shape-complex-sea-machine
)
    set(input "${CMAKE_CURRENT_SOURCE_DIR}/${root}.rl")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/${root}.hh")
    add_custom_command(
        OUTPUT "${output}"
        COMMAND ragel -e -F1 -o "${output}" "${input}"
        MAIN_DEPENDENCY "${input}"
        COMMENT "Generating ${root}.hh"
        VERBATIM
    )
endforeach()

add_library(libharfbuzz
    ${HBSOURCES}
    ${HBHEADERS}
    ${HBNODISTHEADERS}
    ${optional_ucnd_object_libs})

target_include_directories(libharfbuzz PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${libharfbuzz_include_dirs}
)

if(UNIX OR BUILD_SHARED_LIBS)
    set_target_properties(libharfbuzz PROPERTIES
        OUTPUT_NAME harfbuzz)
endif()

if(UNIX)
    set_target_properties(libharfbuzz PROPERTIES
        VERSION ${HB_MAJOR_VERSION}.${HB_LIBTOOL_VERSION_INFO}
        SOVERSION ${HB_MAJOR_VERSION}
        )
else()
    set_target_properties(libharfbuzz PROPERTIES
        VERSION ${HB_VERSION})
endif()

target_link_libraries(libharfbuzz
    PRIVATE ${private_deps}
    PUBLIC ${public_deps})

install(FILES ${HBHEADERS} ${HBNODISTHEADERS} DESTINATION include/harfbuzz)

if(HAVE_ICU)
    add_library(libharfbuzz-icu hb-icu.cc)
    if(UNIX OR BUILD_SHARED_LIBS)
        set_target_properties(libharfbuzz-icu PROPERTIES
            OUTPUT_NAME harfbuzz-icu)
    endif()
    target_link_libraries(libharfbuzz-icu PRIVATE icu libharfbuzz)
    if(UNIX)
        set_target_properties(libharfbuzz-icu PROPERTIES
            VERSION ${HB_MAJOR_VERSION}.${HB_LIBTOOL_VERSION_INFO}
            SOVERSION ${HB_MAJOR_VERSION}
            )
    else()
        set_target_properties(libharfbuzz-icu PROPERTIES
            VERSION ${HB_VERSION})
    endif()
    # install hb-icu.h ?
endif()

if(HAVE_GOBJECT)
    add_library(libharfbuzz-gobject hb-gobject-structs.cc hb-gobject-enums.cc)
    if(UNIX OR BUILD_SHARED_LIBS)
        set_target_properties(libharfbuzz-gobject PROPERTIES
            OUTPUT_NAME harfbuzz-gobject)
    endif()
    target_link_libraries(libharfbuzz-gobject PRIVATE gobject libharfbuzz)
    if(UNIX)
        set_target_properties(libharfbuzz-gobject PROPERTIES
            VERSION ${HB_MAJOR_VERSION}.${HB_LIBTOOL_VERSION_INFO}
            SOVERSION ${HB_MAJOR_VERSION}
            )
    else()
        set_target_properties(libharfbuzz-gobject PROPERTIES
            VERSION ${HB_VERSION})
    endif()
    # install hb-gobject.h hb-gobject-structs.h ?
    # install nodist_pkginclude_HEADERS += hb-gobject-enums.h ?
endif()

#[===[
GENERATORS = \
    gen-arabic-table.py \
    gen-indic-table.py \
    $(NULL)
EXTRA_DIST += $(GENERATORS)

unicode-tables: arabic-table indic-table

indic-table: gen-indic-table.py IndicSyllabicCategory.txt IndicMatraCategory.txt Blocks.txt
    $(AM_V_GEN) $(builddir)/$^ > hb-ot-shape-complex-indic-table.cc \
    || ($(RM) hb-ot-shape-complex-indic-table.cc; false)

arabic-table: gen-arabic-table.py ArabicShaping.txt UnicodeData.txt Blocks.txt
    $(AM_V_GEN) $(builddir)/$^ > hb-ot-shape-complex-arabic-table.hh \
    || ($(RM) hb-ot-shape-complex-arabic-table.hh; false)

built-sources: $(BUILT_SOURCES)

.PHONY: unicode-tables arabic-table indic-table built-sources

BUILT_SOURCES += $(RAGEL_GENERATED)
EXTRA_DIST += \
    hb-buffer-deserialize-json.rl \
    hb-buffer-deserialize-text.rl \
    hb-ot-shape-complex-indic-machine.rl \
    hb-ot-shape-complex-myanmar-machine.rl \
    hb-ot-shape-complex-sea-machine.rl \
    $(NULL)
MAINTAINERCLEANFILES += $(RAGEL_GENERATED)

noinst_PROGRAMS = \
    main \
    test \
    test-buffer-serialize \
    test-size-params \
    test-would-substitute \
    $(NULL)
bin_PROGRAMS =

main_SOURCES = main.cc
main_CPPFLAGS = $(HBCFLAGS)
main_LDADD = libharfbuzz.la $(HBLIBS)

test_SOURCES = test.cc
test_CPPFLAGS = $(HBCFLAGS) $(FREETYPE_CFLAGS)
test_LDADD = libharfbuzz.la $(HBLIBS) $(FREETYPE_LIBS)

test_would_substitute_SOURCES = test-would-substitute.cc
test_would_substitute_CPPFLAGS = $(HBCFLAGS) $(FREETYPE_CFLAGS)
test_would_substitute_LDADD = libharfbuzz.la $(HBLIBS) $(FREETYPE_LIBS)

test_size_params_SOURCES = test-size-params.cc
test_size_params_CPPFLAGS = $(HBCFLAGS)
test_size_params_LDADD = libharfbuzz.la $(HBLIBS)

test_buffer_serialize_SOURCES = test-buffer-serialize.cc
test_buffer_serialize_CPPFLAGS = $(HBCFLAGS)
test_buffer_serialize_LDADD = libharfbuzz.la $(HBLIBS)

dist_check_SCRIPTS = \
    check-c-linkage-decls.sh \
    check-defs.sh \
    check-header-guards.sh \
    check-includes.sh \
    check-libstdc++.sh \
    check-static-inits.sh \
    check-symbols.sh \
    $(NULL)

TESTS = $(dist_check_SCRIPTS)
TESTS_ENVIRONMENT = \
    srcdir="$(srcdir)" \
    MAKE="$(MAKE) $(AM_MAKEFLAGS)" \
    HBSOURCES="$(HBSOURCES)" \
    HBHEADERS="$(HBHEADERS) $(HBNODISTHEADERS)" \
    $(NULL)

if HAVE_INTROSPECTION

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS = HarfBuzz-$(HB_VERSION_MAJOR).0.gir # What does the 0 mean anyway?!
INTROSPECTION_SCANNER_ARGS = -I$(srcdir) -n hb --identifier-prefix=hb_ --warn-all
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)
INTROSPECTION_SCANNER_ENV = CC="$(CC)"

HarfBuzz-0.0.gir: libharfbuzz.la libharfbuzz-gobject.la
HarfBuzz_0_0_gir_INCLUDES = GObject-2.0
HarfBuzz_0_0_gir_CFLAGS = \
    $(INCLUDES) \
    $(HBCFLAGS) \
    -DHB_H \
    -DHB_H_IN \
    -DHB_OT_H \
    -DHB_OT_H_IN \
    -DHB_GOBJECT_H \
    -DHB_GOBJECT_H_IN \
    $(NULL)
HarfBuzz_0_0_gir_LIBS = \
    libharfbuzz.la \
    libharfbuzz-gobject.la \
    $(NULL)
HarfBuzz_0_0_gir_FILES = \
    $(HBHEADERS) \
    $(HBNODISTHEADERS) \
    $(HBSOURCES) \
    hb-gobject-enums.cc \
    hb-gobject-enums.h \
    hb-gobject-structs.cc \
    hb-gobject-structs.h \
    $(NULL)

girdir = $(datadir)/gir-1.0
gir_DATA = $(INTROSPECTION_GIRS)

typelibdir = $(libdir)/girepository-1.0
typelib_DATA = $(INTROSPECTION_GIRS:.gir=.typelib)

CLEANFILES += $(gir_DATA) $(typelib_DATA)

endif

-include $(top_srcdir)/git.mk
]===]
