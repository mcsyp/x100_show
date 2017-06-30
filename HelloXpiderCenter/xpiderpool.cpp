#include "xpiderpool.h"
#include <qdebug.h>
#include <stdio.h>

XpiderPool::XpiderPool(QObject *parent) :QObject(parent)
{
  threadpool_.setMaxThreadCount(MAX_THREADS);//set the max thread pool count
}
XpiderPool::~XpiderPool(){
  Reset();
}
void XpiderPool::Reset(){
  //step1.stop all xpdier clients
  XpiderClient::DisposeAllClients();
  //step2.clear the threadpool
  threadpool_.clear();
}

void XpiderPool::StartConnection(){
  //step1. reset server
  Reset();

  printf("[%s,%d]starting connecting to xpiders.\n",__FUNCTION__,__LINE__);
  //step2.

  const int host_size=10;
  const char* host_list[]={"192.168.1.50",
                           "192.168.1.51",
                           "192.168.1.52",
                           "192.168.1.53",
                           "192.168.1.54",
                           "192.168.1.55",
                           "192.168.1.56",
                           "192.168.1.57",
                           "192.168.1.58",
                           "192.168.1.59"};
  const int host_port=80;
  for(int i=0;i<host_size;++i){
    XpiderClient * x0 = XpiderClient::Create(host_list[i],host_port);
    threadpool_.start(x0);
  }
  printf("[%s,%d] %d xpider_threads created.\n",__FUNCTION__,__LINE__,(int)XpiderClient::g_xpider_list_.size());
}