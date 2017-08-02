cmake_minimum_required(VERSION 3.3)

project(mdorner)

add_custom_command(
	OUTPUT mdbuild
	COMMAND /bin/sh -n "${CMAKE_CURRENT_SOURCE_DIR}/mdbuild.sh"
	COMMAND ${CMAKE_COMMAND} ARGS -E copy "${CMAKE_CURRENT_SOURCE_DIR}/mdbuild.sh" "${CMAKE_CURRENT_BINARY_DIR}/mdbuild"
	MAIN_DEPENDENCY mdbuild.sh
	)

add_custom_target(MdBuild ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/mdbuild")

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/mdbuild"
	DESTINATION /usr/bin
	PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
