include(CMakeParseArguments)

find_package(Git REQUIRED)

function(clone_and_install ARG_NAME)
    set(options "")
    set(svargs GIT_URL SOURCE_DIR)
    set(mvargs CMAKE_ARGS CONFIGURATION_TYPES)

    cmake_parse_arguments(ARG
        "${options}" "${svargs}" "${mvargs}" ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Invalid, unparsed arguments for `clone_and_install()`: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT ARG_CONFIGURATION_TYPES)
        set(ARG_CONFIGURATION_TYPES Debug Release)
    endif()

    if(NOT ARG_GIT_URL)
        message(FATAL_ERROR "Missing GIT_URL")
    endif()

    set(binary_dir_base ${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}-build)
    set(clone_dir ${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}-repo)

    if(NOT IS_DIRECTORY ${clone_dir})
        set(command_line clone --recurse "${ARG_GIT_URL}" "${clone_dir}")
        string(REPLACE ";" " " s "${command_line}")
        message(STATUS "git ${s}")
        execute_process(COMMAND ${GIT_EXECUTABLE} ${command_line}
            RESULT_VARIABLE result)
        if(result)
            file(REMOVE_RECURSE ${clone_dir})
            message(FATAL_ERROR "Failed to git-clone ${ARG_GIT_URL}")
        endif()
    endif()

    set(cmake_args "")
    if(CMAKE_INSTALL_PREFIX)
        list(APPEND cmake_args "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}")
    endif()
    if(CMAKE_PREFIX_PATH)
        list(APPEND cmake_args "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")
    endif()
    if(ARG_SOURCE_DIR)
        if(IS_ABSOLUTE "${ARG_SOURCE_DIR}")
            message(FATAL_ERROR "SOURCE_DIR must be a relative path, current value: ${ARG_SOURCE_DIR}")
        endif()
        set(source_dir "${clone_dir}/${ARG_SOURCE_DIR}")
    else()
        set(source_dir "${clone_dir}")
    endif()

    if(NOT EXISTS "${source_dir}/CMakeLists.txt")
        message("The source dir \"${source_dir}\" does not contain `CMakeLists.txt`")
    endif()

    # configure and build
    foreach(c ${ARG_CONFIGURATION_TYPES})
        set(command_line
                -G "${CMAKE_GENERATOR}"
                ${cmake_args}
                ${ARG_CMAKE_ARGS}
            )
        if(CMAKE_CONFIGURATION_TYPES)
            set(binary_dir "${binary_dir_base}")
        else()
            set(binary_dir "${binary_dir_base}-${c}")
            list(APPEND command_line -DCMAKE_BUILD_TYPE=${c})
        endif()

        list(APPEND command_line "${source_dir}")

        message(STATUS "cd ${binary_dir}")
        string(REPLACE ";" " " s "${command_line}")
        message(STATUS "cmake ${s}")

        file(MAKE_DIRECTORY ${binary_dir})

        execute_process(COMMAND ${CMAKE_COMMAND} ${command_line}
            WORKING_DIRECTORY ${binary_dir}
            RESULT_VARIABLE result
        )
        if(result)
            message(FATAL_ERROR "Failed to configure ${source_dir} -> ${binary_dir}")
        endif()

        set(command_line
            --build "${binary_dir}"
        )

        if(CMAKE_CONFIGURATION_TYPES)
            list(APPEND command_line --config ${c})
        endif()

        string(REPLACE ";" " " s "${command_line}")
        message(STATUS "cmake ${s}")
        execute_process(COMMAND ${CMAKE_COMMAND} ${command_line}
            RESULT_VARIABLE result)

        if(result)
            message(FATAL_ERROR "Failed to build ${binary_dir}")
        endif()
    endforeach()

    # Install is done in a seperate loop. Reason:
    # In case the Debug or Release builds fails nothing will be installed.
    # And this is good, because in the next run of the caller CMakeLists.txt
    # it won't find anything when it tries to `find_package` the package whose
    # build has been failed before, so it will try again to build.

    foreach(c ${ARG_CONFIGURATION_TYPES})
        if(CMAKE_CONFIGURATION_TYPES)
            set(binary_dir "${binary_dir_base}")
        else()
            set(binary_dir "${binary_dir_base}-${c}")
        endif()

        set(command_line
            --build "${binary_dir}"
            --target install
        )

        if(CMAKE_CONFIGURATION_TYPES)
            list(APPEND command_line --config ${c})
        endif()

        string(REPLACE ";" " " s "${command_line}")
        message(STATUS "cmake ${s}")
        execute_process(COMMAND ${CMAKE_COMMAND} ${command_line}
            RESULT_VARIABLE result)

        if(result)
            message(FATAL_ERROR "Failed to install ${binary_dir}")
        endif()
    endforeach()

endfunction()
