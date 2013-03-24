import QtQuick 1.1

import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.extras 0.1 as PlasmaExtras
import org.kde.qtextracomponents 0.1

import org.kde.workflow.components 0.1 as WorkFlowComponents

import "."

Item{
    property int minimumWidth: 10
    property int minimumHeight: 10
   /* property int maximumWidth: 256
    property int maximumHeight: 256
    property int preferredWidth: 256
    property int preferredHeight: 256*/

    WorkFlowComponents.SessionParameters {
        id: sessionParameters
    }

    onWidthChanged: checkLayout();
    onHeightChanged: checkLayout();

    function checkLayout() {
        switch(plasmoid.formFactor) {
        case Vertical:
            plasmoid.setPreferredSize(width, width);
            break;

        case Horizontal:
            plasmoid.setPreferredSize(height, height);
            break;

        default:
            plasmoid.setPreferredSize(height, height);
            break;
        }
    }

    IconButton{
        id:mainIcon
        anchors.centerIn: parent

        width:parent.width
        height:parent.height
        icon: iconPath
        smooth:true
      //  active:mouseAreaContainer.containsMouse
        opacity: mouseAreaContainer.containsMouse ? 1 : 0.93

        property string iconPath: sessionParameters.currentActivityIcon;

        Behavior on opacity{
            NumberAnimation {
                duration:  Settings.global.animationStep;
                easing.type: Easing.InOutQuad;
            }
        }

        IconButton{
            anchors.right: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter

            width:parent.width/2
            height:parent.height/2
            icon: "preferences-activities"
            smooth:true
            visible: Settings.global.useCurrentActivityIcon
        //    active:mouseAreaContainer.containsMouse
        }
    }


    /*PlasmaCore.IconItem{
        id:mainIcon
        anchors.fill: parent
        source: sessionParameters.currentActivityIcon
        smooth:true
        active:mouseAreaContainer.containsMouse

        PlasmaCore.IconItem{
            anchors.right: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter

            width:parent.width/2
            height:parent.height/2
            source:"preferences-activities"
            smooth:true

            active:mouseAreaContainer.containsMouse
        }
    }*/

    PlasmaExtras.PressedAnimation{
        id:pressedAnimation
        targetItem:mainIcon
    }

    PlasmaExtras.ReleasedAnimation{
        id:releasedAnimation
        targetItem:mainIcon
    }

    ///?Workareas engine
    PlasmaCore.DataSource {
        id: workareaSource
        engine: "workareas"
        connectedSources: sources
        onDataChanged: {
            connectedSources = sources
        }
    }

    //this timer helps in order not to send too many signal
    //of changing current activity through mouse wheel
    //(changing activities with not logical order fixed this way)
    Timer {
        id:timer
        interval: 150; running: false; repeat: false
        onTriggered: wheelListener.enabledTimer = false;
    }

    MouseEventListener {
        id:wheelListener
        anchors.fill:parent
        property bool enabledTimer:false

        onWheelMoved:{
            if(!enabledTimer){
                enabledTimer = true;
                timer.start();
                if(wheel.delta < 0){
                    var service = workareaSource.serviceForSource("");
                    var operation = service.operationDescription("setCurrentPreviousActivity");
                    service.startOperationCall(operation);
                }
                else{
                    var service2 = workareaSource.serviceForSource("");
                    var operation2= service2.operationDescription("setCurrentNextActivity");
                    service2.startOperationCall(operation2);
                }
            }
        }

        MouseArea{
            id:mouseAreaContainer
            anchors.fill:parent
            hoverEnabled: true
            onClicked:{
                sessionParameters.triggerKWinScript();
            }

            onPressed: pressedAnimation.start();
            onReleased: releasedAnimation.start();
        }

        PlasmaCore.ToolTip{
            target:mouseAreaContainer
            mainText: i18n("KWin WorkFlow Script Launcher");
            subText: i18n("A simple launcher for the KWin WorkFlow Script")
            image: mainIcon.source
        }
    }


    Component.onCompleted:{
        plasmoid.aspectRatioMode = "ConstrainedSquare"
        checkLayout();
    }
}
