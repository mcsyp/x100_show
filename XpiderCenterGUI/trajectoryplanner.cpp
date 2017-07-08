#include "trajectoryplanner.h"

TrajectoryPlanner::TrajectoryPlanner()
{
  max_dis_id = 0;
  max_dis_x = 0;
  max_dis_y = 0;
  min_dis = 0.15;             //20cm
  min_target_dis = 0.06;      //6cm
  target_len_ = 0;
  wait_max_number = 6;
};

bool TrajectoryPlanner::Reset(float width, float height, xpider_target_point_t target_list[], int target_len){
  float target_dis = 0;
  for (int i=0; i<target_len; i++){
    float target_dis_ = sqrt(pow(target_list[i].target_x,2)+pow(target_list[i].target_y,2));
    if (target_dis_ > target_dis){
      target_dis = target_dis_;                //找到最大的距离值
      max_dis_id = target_list[i].id;          //记录最大距离值的ID
      max_dis_x = target_list[i].target_x;
      max_dis_y = target_list[i].target_y;
    }
    target_list_[i].id = target_list[i].id;
    target_list_[i].target_x = target_list[i].target_x;
    target_list_[i].target_y = target_list[i].target_y;
  }
  target_len_ = target_len;
  return true;
}

int TrajectoryPlanner::Plan(xpider_opti_t info[], int info_len, xpider_tp_t out_action[],int out_size){

  float info_target_dis;

  //step1:计算当前位置和最大距离值点的距离，判断优先级
  float priority[out_size];
  for (int i=0; i<info_len; i++){
    float p = sqrt(pow((info[i].x-max_dis_x),2)+pow((info[i].y-max_dis_y),2));
    priority[i] = p;
    //qDebug()<<"priority["<<i<<"]"<<priority[i];
  }

  //step2:计算旋转角度，行走步数
  for (int i=0; i<info_len; i++) {
    for(int j=0; j<info_len; j++) {
      if (info[i].id==target_list_[j].id) {
        info_target_dis = sqrt(pow((target_list_[j].target_y-info[i].y),2)+pow((target_list_[j].target_x-info[i].x),2));
        float A1 = acos((target_list_[j].target_x-info[i].x)/info_target_dis);
        if (target_list_[j].target_y-info[i].y<0) {
          A1 = 2*PI-A1;                               //A1~(0,2PI)
        }
        //qDebug()<<"A1:"<<A1*180/PI;
        float D_a = fabs(info[i].theta-A1);
        float D_b = 2*PI-D_a;
        float D_min = ((D_a>D_b)?D_b:D_a);
        if((A1-D_min)==info[i].theta) {
          D_min = -D_min;
        }
        out_action[i].delta_theta = D_min;
        out_action[i].detla_step = 3;
      }
    }
  }

  //step3:计算每个id之间的距离值
  for (int i=0; i<info_len; i++) {
    for (int j=0; j<info_len; j++) {
      if (info[i].id<info[j].id) {
        float D_dist = sqrt(pow((info[i].x-info[j].x),2)+pow((info[i].y-info[j].y),2));
        //qDebug()<<"ID_to_ID_distence:"<<D_dist;
        if (D_dist<min_dis){
          if (priority[i]<priority[j]) {
            out_action[j].detla_step = 0;    //低于安全距离的，优先级低置零
            id_to_id[j] = id_to_id[j]+1;
          } else {
            out_action[i].detla_step = 0;
            id_to_id[i] = id_to_id[i]+1;
          }
        }
      }
    }
  }

  //step4:给ID赋值;若长时间等待，转角90°
  for (int i=0; i<info_len; i++) {
    out_action[i].id = target_list_[i].id;
    //if (id_to_id[i]==wait_max_number) {
    //  out_action[i].delta_theta = out_action[i].delta_theta + PI/2;
    //  out_action[i].detla_step = 3;
    //  id_to_id[i] = 0;
    //}
  }

  //step5:计算每个ID与目标点之间的距离值
  /*for (int i=0; i<info_len; i++) {
    float aim_dis = sqrt(pow((info[i].x-target_list_[i].target_x),2)+pow((info[i].y-target_list_[i].target_y),2));
    //qDebug()<<"aim_dis["<<i<<"]"<<aim_dis;
    if (aim_dis<min_target_dis) {
      out_action[i].detla_step = 0;
      out_action[i].delta_theta = 0;
    }
  }*/

  for(int i=0; i<info_len; i++){
    qDebug()<<"out_action["<<i<<"]:       ID:"<<out_action[i].id;
    //qDebug()<<"out_action["<<i<<"]:delta_theta:"<<out_action[i].delta_theta;
    qDebug()<<"out_action["<<i<<"]:          θ:"<<(out_action[i].delta_theta)*(180/PI);
    qDebug()<<"out_action["<<i<<"]: detla_step:"<<out_action[i].detla_step;
    qDebug()<<'\n';
  }
  return info_len;
}
