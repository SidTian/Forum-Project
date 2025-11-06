cmake_minimum_required(VERSION 3.16)

project(Forum VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Network REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appForum
    main.cpp
    qml.qrc
)

qt_add_qml_module(appForum
    URI Forum
    VERSION 1.0
    QML_FILES
        Main.qml
        QML_FILES LoginDialog.qml
        QML_FILES NewPostDialog.qml
        QML_FILES
        RESOURCES qml.qrc
        RESOURCES
        RESOURCES
        SOURCES
        SOURCES
)

qt_add_resources(appForum "qml"
    PREFIX "/"
    FILES
        Main.qml
        LoginDialog.qml
        NewPostDialog.qml
        PostDetails.qml
)

set_source_files_properties(PromptDialog.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)


# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appForum PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appForum
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appForum PRIVATE Qt6::Core Qt6::Quick Qt6::QuickControls2 Qt6::Network)

include(GNUInstallDirs)
install(TARGETS appForum
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

