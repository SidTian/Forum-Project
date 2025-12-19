cmake_minimum_required(VERSION 3.16)
project(Forum VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Network Test)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appForum
    main.cpp
)

qt_add_qml_module(appForum
    URI Forum
    VERSION 1.0
    QML_FILES
        Main.qml
        LoginDialog.qml
        NewPostDialog.qml
        PostDetails.qml
        UserDetail.qml
        Prompt.qml
    SOURCES
        User.cpp
        User.h
        UserManager.cpp
        UserManager.h
        SOURCES
        SOURCES ChannelAdmin.h
        SOURCES Admin.h
        SOURCES UserFactory.h
        SOURCES
        SOURCES
        SOURCES
        SOURCES NormalUser.h
        SOURCES NormalUser.cpp
        SOURCES ChannelAdmin.cpp
        SOURCES Admin.cpp
)

set_target_properties(appForum PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appForum PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
)



# ==================== 测试部分 ====================
enable_testing()

include(FetchContent)
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.17.0.zip
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# 你的测试文件
add_executable(my_tests
    tst_user.cpp
    User.cpp
    UserManager.cpp
    NormalUser.cpp
    ChannelAdmin.cpp
    Admin.cpp
)

target_link_libraries(my_tests PRIVATE
    gtest_main
    gmock
    Qt6::Core
    Qt6::Gui
    Qt6::Test
)

# 下面 3 行是关键！让 Qt Creator 能找到可执行文件
set_target_properties(my_tests PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
    OUTPUT_NAME "my_tests"
)

# 自动发现所有 TEST() 测试用例
include(GoogleTest)
gtest_discover_tests(my_tests)

# 让 make test 能直接运行
add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --verbose
    DEPENDS my_tests
)
