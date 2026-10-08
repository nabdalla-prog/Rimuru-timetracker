import QtQuick
import qs.qml

// One Nerd Font glyph.
Text {
    property string glyph: ""
    property int size: 18
    text: glyph
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
