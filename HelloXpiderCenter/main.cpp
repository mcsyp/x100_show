#include <QCoreApplication>
#include  "serverxpider.h"
#include <stdio.h>
int main(int argc, char *argv[])
{
  QCoreApplication a(argc, argv);
  ServerXpider server_xpider;
  server_xpider.StartServer();
  return a.exec();
}
