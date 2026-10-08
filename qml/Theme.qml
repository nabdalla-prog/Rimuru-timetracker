pragma Singleton
import QtQuick
import Quickshell

// The look of the reference: true black, iOS-style grey cards, blue accent.
Singleton {
    readonly property color bg: "#000000"
    readonly property color card: "#1c1c1e"
    readonly property color cardHi: "#2c2c2e"
    readonly property color separator: "#38383a"
    readonly property color text: "#ffffff"
    readonly property color text2: "#8e8e93"
    readonly property color text3: "#636366"
    readonly property color accent: "#0a84ff"
    readonly property color danger: "#ff453a"
    readonly property color good: "#30d158"

    readonly property string font: "Noto Sans"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    readonly property int small: 12
    readonly property int body: 15
    readonly property int tile: 16
    readonly property int title: 17
    readonly property int large: 30

    readonly property int radius: 12
    readonly property int pad: 14

    // Nerd Font glyphs.
    readonly property string iClock: ""
    readonly property string iEvents: ""
    readonly property string iTimeline: ""
    readonly property string iGoals: ""
    readonly property string iSettings: ""
    readonly property string iPlus: ""
    readonly property string iGrid: ""
    readonly property string iList: ""
    readonly property string iPie: ""
    readonly property string iBars: ""
    readonly property string iLeft: ""
    readonly property string iRight: ""
    readonly property string iCheck: ""
    readonly property string iStop: ""
    readonly property string iBell: ""
    readonly property string iExport: ""
    readonly property string iTrash: ""
    readonly property string iCalendar: ""
    readonly property string iHash: ""
    readonly property string iArchive: ""
    readonly property string iBrush: ""
    readonly property string iInfo: ""
    readonly property string iClone: ""
    readonly property string iPencil: ""
    readonly property string iUp: ""
    readonly property string iDown: ""
    readonly property string iEye: ""
    readonly property string iEyeOff: ""
    readonly property string iHeart: ""
    readonly property string iRound: ""
    readonly property string iFlag: ""
    readonly property string iClose: ""
}
