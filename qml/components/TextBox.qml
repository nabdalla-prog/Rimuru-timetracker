import QtQuick
import qs.qml

// A one-line text field.
//
// The TextInput inside stays read-only and this file does the typing itself.
// An editable TextInput reads the whole clipboard every time the clipboard
// changes (to keep `canPaste` current), whether or not it has focus or is even
// on screen, so any program that owns the clipboard could stall or exhaust
// this one by streaming endless text. Read-only skips that read, so here the
// clipboard is read only when the user presses the paste shortcut. The price
// is no undo and no input-method composition in this field.
Rectangle {
    id: root
    property alias text: input.text
    property string placeholder: ""
    readonly property bool editing: input.activeFocus
    signal submitted(string text)

    function focusInput() {
        input.forceActiveFocus();
        input.selectAll();
    }

    width: parent ? parent.width : 300
    height: 42
    radius: 10
    color: Theme.cardHi
    border.width: input.activeFocus ? 1.5 : 0
    border.color: Theme.accent

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        selectByMouse: true
        maximumLength: 40
        color: Theme.text
        selectionColor: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.body
        readOnly: true
        cursorVisible: activeFocus

        // Replaces the selection (if any) with `s`. insert() honours
        // maximumLength.
        function type(s) {
            if (selectionStart !== selectionEnd)
                remove(selectionStart, selectionEnd);
            insert(cursorPosition, s);
        }
        // Deletes the selection, or else `count` characters before (negative)
        // or after (positive) the cursor, keeping surrogate pairs whole.
        function erase(count) {
            if (selectionStart !== selectionEnd) {
                remove(selectionStart, selectionEnd);
                return;
            }
            let from = cursorPosition, to = cursorPosition + count;
            const code = i => text.charCodeAt(i);
            if (count < 0 && to > 0 && code(to) >= 0xDC00 && code(to) <= 0xDFFF)
                to--;
            else if (count > 0 && to < length && code(to - 1) >= 0xD800 && code(to - 1) <= 0xDBFF)
                to++;
            remove(Math.max(0, Math.min(from, to)), Math.min(length, Math.max(from, to)));
        }
        // How far the previous word starts before the cursor (Ctrl+Backspace).
        function wordBefore() {
            const m = /\S*\s*$/.exec(text.slice(0, cursorPosition));
            return Math.max(1, m ? m[0].length : 1);
        }
        // The only clipboard read: paste() needs an editable field, so it is
        // editable for exactly this call. Switching moves the cursor to the
        // end, hence the saving and restoring around it.
        function pasteNow() {
            const a = selectionStart, b = selectionEnd, at = cursorPosition;
            readOnly = false;
            if (a !== b)
                select(a, b);
            else
                cursorPosition = at;
            paste();
            const after = cursorPosition;
            readOnly = true;
            cursorPosition = after;
            cursorVisible = Qt.binding(() => activeFocus);
        }

        Keys.onPressed: function (event) {
            const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.submitted(text);
            } else if (event.matches(StandardKey.Paste)) {
                pasteNow();
            } else if (event.matches(StandardKey.Cut)) {
                copy();
                erase(0);
            } else if (event.key === Qt.Key_Backspace) {
                erase(ctrl ? -wordBefore() : -1);
            } else if (event.key === Qt.Key_Delete) {
                erase(1);
            } else {
                // Printable text only. Shortcuts and control characters fall
                // through to the TextInput (copy, select all, moving the
                // cursor). Ctrl with Alt is how some layouts send AltGr.
                const alt = (event.modifiers & Qt.AltModifier) !== 0;
                const c = event.text.length ? event.text.charCodeAt(0) : 0;
                if ((ctrl && !alt) || c < 0x20 || c === 0x7F)
                    return;
                type(event.text);
            }
            event.accepted = true;
        }
    }
    Label {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: root.placeholder
        color: Theme.text3
    }
}
