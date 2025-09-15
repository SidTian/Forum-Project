#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // 注册全局 PromptDialog
    QObject *promptDialog = nullptr;
    QQmlComponent component(&engine, QUrl("qrc:/PromptDialog.qml"));
    if (!component.isError()) {
        promptDialog = component.create();
        if (promptDialog) {
            engine.rootContext()->setContextProperty("globalPromptDialog", promptDialog);
            qDebug() << "PromptDialog registered successfully";
        } else {
            qWarning() << "Failed to create PromptDialog instance";
        }
    } else {
        qWarning() << "Failed to load PromptDialog:" << component.errorString();
    }


    // 加载 QML 模块
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Forum", "Main");

    return app.exec();
}
