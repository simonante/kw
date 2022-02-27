import QtQuick 2.6
import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 1.0
import io.singleton 1.0

Window {
    visible: true;
    title: qsTr("edit")
    width: 1404;
    height: 1872;

    property int rotation: 0
    property string doc: "# reMarkable key-writer";
    property int mode: 1;
    property bool ctrlPressed: false;
    property bool isOmni: false;
    property string omniQuery: "";
    property string currentFile: "scratch.md";

    readonly property int dummy: onLoad();

    function toggleMode() {
        if (mode == 0) {
            mode = 1;
        } else {
            doc = query.text;
            mode = 0;
        }
        saveFile();
    }

    function doLoad(name) {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "file:///home/root/edit/" + name);
        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                var response = xhr.responseText;
                isOmni = false;
                mode = 0;
                currentFile = name;
                doc = response;
            }
        };
        xhr.send();
    }

    function saveFile() {
        console.log("Save " + currentFile);
        var fileUrl = "file:///home/root/edit/" + currentFile;
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send(doc);
        console.log("save -> " + request.status + " " + request.statusText);
        return request.status;
    }

    function initFile(name) {
        console.log("Init " + name);
        var fileUrl = "file:///home/root/edit/" + name + ".md";
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send("# " + name);
        console.log("save -> " + request.status + " " + request.statusText);
        return request.status;
    }

    function handleKeyDown(event) {
        if (event.key == Qt.Key_Control) {
            ctrlPressed = true;
        } else if (event.key == Qt.Key_K && ctrlPressed) {
            isOmni = !isOmni;
            event.accepted = true;
        }
    }
    function handleKeyUp(event) {
        if (event.key == Qt.Key_Control) {
            ctrlPressed = false;
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            if (isOmni) {
                isOmni = false;
            } else {

                toggleMode();
            }
        }

        if (mode == 1)
             switch(event.key) {
                 case Qt.Key_Home:
                     Qt.quit()
                     break;
                 case Qt.Key_Right:
                     if (ctrlPressed)
                         root.rotation = (root.rotation+90) % 360
                     break;
                 case Qt.Key_Left:
                     if (ctrlPressed)
                         root.rotation = (root.rotation-90) % 360
                     break;
             }
    }

    function onLoad() {
        doLoad(currentFile);
        return 0;
    }
    Rectangle {
         anchors.fill: parent
         color: "white"
     }

    Rectangle {
        rotation: root.rotation
        anchors.top: parent.right
        y: 200
        width: (root.rotation / 90 ) % 2 ? root.height : root.width
        height: (root.rotation / 90 ) % 2 ? root.width : root.height
        color: "white"
        EditUtils {
             id: utils
         }
         FolderListModel {
             id: folderModel
             folder: root.folder
             nameFilters: ["*.md"]
         }

        Flickable {
            id: flick
            width: 1404;
            height: 1404;
            contentWidth: query.paintedWidth
            contentHeight: query.paintedHeight
            clip: true

            function ensureVisible(r)
            {
                if (contentX >= r.x)
                    contentX = r.x;
                else if (contentX+width <= r.x+r.width)
                    contentX = r.x+r.width-width;
                if (contentY >= r.y)
                    contentY = r.y;
                else if (contentY+height <= r.y+r.height)
                    contentY = r.y+r.height-height;
            }
            
            function scrollUpSmall() {
                contentY -= 400;
            }
            function scrollDownSmall() {
                contentY += 400;
            }

            function scrollUpBig() {
                contentY -= 45000;
            }
            function scrollDownBig() {
                contentY += 45000;
            }
            

            TextEdit {
                id: query;
                Keys.enabled: true;
                wrapMode: TextEdit.Wrap;
                textMargin: 12;
                width:1404;
                textFormat: mode == 0 ? TextEdit.RichText : TextEdit.PlainText;
                font.family: mode == 0 ? "Noto Sans" : "Noto Mono";
                text: mode == 0 ? utils.markdown(doc) : doc;
                focus: !isOmni;
                Component {
                    id: curDelegate
                    Rectangle { width:8; height: 20; visible: query.cursorVisible; color: "black";}
                }
                cursorDelegate: curDelegate;
                readOnly: mode == 0 ? true : false;
                font.pointSize: mode == 0 ? 9 : 9;

                onLinkActivated: {
                    console.log("Link activated: " + link);
                    doLoad(link);
                }

                Keys.onPressed: {
                    if (mode == 1 && (event.key == Qt.Key_Down)) {
                        flick.scrollDownSmall();
                    }
                    if (mode == 1 && (event.key == Qt.Key_Up)) {
                        flick.scrollUpSmall();
                    }                
                    if (mode == 1 && (event.key == Qt.Key_S && ctrlPressed)) {
                        flick.scrollDownBig();
                    }
                    if (mode == 1 && (event.key == Qt.Key_W && ctrlPressed)) {
                        flick.scrollUpBig();
                    }

                    handleKeyDown(event);
                }

                Keys.onReleased: {
                    handleKeyUp(event);
                    handleKey(event);
                }
            }
        }

    }
    Rectangle {
        id: quick
        rotation: root.rotation
        anchors.centerIn: parent;
        width: 1000;
        height: 700;
        color: "black"
        visible: isOmni ? true : false;
        radius: 20;
        border.width: 5;
        border.color: "gray";

        TextEdit {
            id: omniQueryTextEdit;
            text: omniQuery;
            textFormat: TextEdit.PlainText;
            x: 40;
            width:980;
            color: "white";
            font.pointSize: 20;
            font.family: "Noto Mono";
            focus: isOmni;
            Keys.enabled: true;
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    saveFile();
                    if (!omniList.currentItem) {
                        initFile(omniQuery);
                        doLoad(omniQuery + ".md");
                    } else {
                        doLoad(omniList.currentItem.text);
                    }
                    isOmni = false;
                    event.accepted = true;
                    return;
                }

                handleKeyDown(event);
            }
            Keys.onReleased: {
                handleKeyUp(event);
                handleKey(event);
                omniQuery = omniQueryTextEdit.text;
                folderModel.nameFilters = [omniQuery + "*"];
            }

            anchors {top: parent.top + 10; left: parent.left + 10}
            Keys.forwardTo: [omniList]
        }
        ListView {
            id: omniList;
            x: 40;
            width: 900; height: 600;
            anchors.top: omniQueryTextEdit.bottom;
            highlight: Rectangle { color: "white"; radius: 5;width: 900; }
            Component {
                id: fileDelegate
                Text { width:900; text: fileName; color: ListView.isCurrentItem ? "black" : "white";}
            }

            model: folderModel
            delegate: fileDelegate
        }

    }

}
