#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>

#include "PostModel.h"
#include "LoginManager.h"
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    PostModel postModel;
    engine.rootContext()->setContextProperty("postModel", &postModel);

    LoginManager loginManager;
    engine.rootContext()->setContextProperty("loginManager", &loginManager);

    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
