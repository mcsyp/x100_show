import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

Rectangle {
    id:playground_
    property var xpider_queue_ : new Array()
    property var target_queue_ : new Array()
    property var cross_queue_ : new Array()

    property var max_xpider_num_:100
    property var real_width_:4.5 //3 meter
    property var real_height_:4.5 //2 meter

    property var reset_pos_:-500
    property var selected_xpider_index_:-1
    property var opti_counter_:0
    property var xpider_available_counter_:0


    function createXpider(num){
        var component = Qt.createComponent("Xpider.qml");
        if(component.status===Component.Ready){
            for(var i=0;i<num;++i){
                var dynamic_comp_ = component.createObject(playground_,
                                                       {"x":reset_pos_,
                                                        "y":reset_pos_,
                                                        "dev_id":i,
                                                        "z":10,
                                                        "visible":false,});
                xpider_queue_.push(dynamic_comp_);
            }
        }
    }
    function createTarget(num){
        var component = Qt.createComponent("Target.qml");
        if(component.status===Component.Ready){
            for(var i=0;i<num;++i){
                var dynamic_comp_ = component.createObject(playground_,
                                                       {"x":reset_pos_,
                                                        "y":reset_pos_,
                                                        "dev_id":i,
                                                        "z":5,
                                                        "visible":true,});

                target_queue_.push(dynamic_comp_);
            }
        }
    }
    function createLandmarks(num){
        var component = Qt.createComponent("Cross.qml");
        if(component.status===Component.Ready){
            for(var i=0;i<num;++i){
                var dynamic_comp_ = component.createObject(playground_,
                                                       {"x":reset_pos_,
                                                        "y":reset_pos_,
                                                        "z":2,
                                                        "index_":i,
                                                        "visible":true,});
                cross_queue_.push(dynamic_comp_);
            }
        }
    }
    function convertFromRealToScreen(real_x,real_y){
        var screen_x,screen_y;
        screen_x = (real_x/real_width_+0.5)*main_window_.width
        screen_y = (0.5-real_y/real_height_)*main_window_.height
        return [screen_x,screen_y];
    }
    function convertFromScreenToReal(screen_x,screen_y){
        var real_x,real_y;
        real_x = (screen_x/main_window_.width-0.5)*real_width_;
        real_y = (0.5-screen_y/main_window_.height)*real_height_;
        return [real_x,real_y];
    }

    Timer{
        id:target_timer
        repeat: true
        interval: 1000
        onTriggered: {

        }
    }

    MouseArea{
        anchors.fill: parent        
        acceptedButtons: Qt.LeftButton| Qt.RightButton
        onClicked: {
            switch(mouse.button){
            case Qt.LeftButton:
                selectXpider(mouse.x,mouse.y);
                break;
            case Qt.RightButton:
                if(selected_xpider_index_>=0){
                    var dev_id = xpider_queue_[selected_xpider_index_].dev_id;
                    var real_pos = convertFromScreenToReal(mouse.x,mouse.y);
                    opti_server_.pushTarget(dev_id,real_pos[0],real_pos[1]);
                }
                break;
            }
            var click_pos = convertFromScreenToReal(mouse.x,mouse.y);
            //console.log("clicked:"+click_pos[0]+","+click_pos[1]);
        }
    }
    function selectXpider(x,y){
        var min_dis=1000;
        var min_index=0;
        for(var i=0;i<xpider_queue_.length;++i){
            var xpider = xpider_queue_[i];
            var d = Math.abs(x-xpider.x)+Math.abs(y-xpider.y);
            if(d<min_dis){
                min_dis = d;
                min_index=i;
            }
        }

        //console.log("min_dis is:",min_dis);
        if(min_dis<40 && xpider_queue_[min_index].dev_id>=0){
            var selected = !xpider_queue_[min_index].selected_;
            opti_server_.uiSelectXpider(xpider_queue_[min_index].dev_id,selected);
            if(!selected){
                opti_server_.removeTarget(xpider_queue_[min_index].dev_id);
            }
        }
    }

    function resetAllTargets(){
        opti_server_.clearTargets()
    }

    Connections{
        target: opti_server_
        onXpiderListUpdate:{
            var xpider_list = JSON.parse(str_json);
            opti_counter_ = xpider_list.length;
            var available_counter=0;
            for(var i=0;i<xpider_queue_.length;++i){
                if(i<xpider_list.length){
                    var xpider = xpider_list[i];

                    //show xpider
                    var screen_pos=convertFromRealToScreen(xpider.x,xpider.y);
                    xpider_queue_[i].x = screen_pos[0];
                    xpider_queue_[i].y = screen_pos[1];
                    var angle = (90-xpider.theta*180.0/Math.PI)%360
                    xpider_queue_[i].rotation=angle;
                    xpider_queue_[i].dev_id = xpider.id;
                    xpider_queue_[i].label_ = xpider.label;
                    xpider_queue_[i].visible = true;
                    xpider_queue_[i].setSelected(xpider.id>=0 && xpider.selected);

                    //show target
                    if(xpider.id>=0){
                        screen_pos=convertFromRealToScreen(xpider.target_x,xpider.target_y);
                        target_queue_[i].x = screen_pos[0]
                        target_queue_[i].y = screen_pos[1]
                        target_queue_[i].dev_id = xpider.id;
                        target_queue_[i].visible=true;
                        //console.log("id:",xpider.id,
                        //            " x:",xpider_queue_[i].x,
                        //            " y:",xpider_queue_[i].y,
                        //            " target_x:",target_queue_[i].x,
                        //            " target_y:",target_queue_[i].y);
                        if(xpider.selected){
                            selected_xpider_index_ = i;//selected index is JUST INDEX. NOT ID!!
                            //console.log("selected xpider id is ",xpider.id);
                        }
                        ++available_counter;
                    }

                }else{
                    xpider_queue_[i].visible = false;
                    target_queue_[i].visible = false;
                }
                xpider_available_counter_ = available_counter
            }
        }
        onLandmarkListUpdate:{
            var mark_list = JSON.parse(str_json);
            for(var i=0;i<cross_queue_.length;++i){
                if(i<mark_list.length){
                    var mark= mark_list[i];
                    var screen_pos = convertFromRealToScreen(mark.x,mark.y);
                    cross_queue_[i].x = screen_pos[0];
                    cross_queue_[i].y = screen_pos[1];
                    cross_queue_[i].cross_id = mark.id;
                    cross_queue_[i].visible = true;
                }else{
                    cross_queue_[i].visible = false;
                }
            }
        }

        onServiceInitializing:{
            createXpider(max_xpider_num_)
            createTarget(max_xpider_num_)
            createLandmarks(max_xpider_num_)
            console.log("xpdier queue intialized:",xpider_queue_.length);
            console.log("target queue intialized:",target_queue_.length);
            console.log("landmark queue intialized:",cross_queue_.length);
        }
    }
}
