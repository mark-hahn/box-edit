
## box-edit

An Atom package to edit rectangular areas; supports short lines.

![box-edit-demo](https://cloud.githubusercontent.com/assets/811455/11103846/ea8676f2-8879-11e5-80fd-deb13f47cf89.gif)

Box-edit provides for selecting and editing a box (rectangular area) of text in the Atom editor. When in box mode the Atom cursors disappear and a new red box cursor takes over.  You can cut, paste, insert, etc., on a box instead of character strings. Box-edit supports virtual spaces to the right of lines which solves a problem found in rectangular selection tools that use Atom cursors/selections.

### Features

- A box can be selected, cut, and pasted anywhere, even to the right of lines.
- Supports wrapped lines properly.
- The box can be filled with any character, such as a space, to blank an area.
- The box mode supports basic editor commands such as cut, copy, paste, and undo/redo.
- A box can be turned into a character-based editor (an html textarea) which allows typing wrapped text into a rectangle.  Useful for comments to the right of multiple lines.
- When opening a box, Atom cursors are converted into a box, and when closing the box it is converted back into Atom selections. So by switching back and forth you can create Atom cursor-based rectangles like other packages do.

## Usage

**Installation** Install box-edit using `apm install box-edit`.  

**Entering/Exiting Box Mode** The command to toggle box mode on and off is `box-edit:toggle` which by default is bound to `Alt-S`. You can tell you are in box mode when the Atom selections disappear and a red box appears (unless it is outside of the visible area).  The mouse cursor changes into a cross-hair.

**Selecting** When in box mode you can create a box by clicking and dragging the mouse. The box will be shown as a red rectangle.  The support of arrow keys is planned for the future.  You may select anywhere in the editor pane including to the right of line endings.

**Single Clicking** If you click without dragging then a zero-width box  will be created. This is useful before inserting a box.  You can also extend it to a bigger box using shift-click. 

**Extending Selection** Shift-click will move the second corner of a box to the new point. This allows extending/shrinking a selection. If you wish to create a box that is taller/wider than the current screen then you must select one corner with a single-click, scroll the pane, and then shift-click to set the second corner.

**Atom Selection Matching** When you enter box-mode a new box will be created that surrounds all existing Atom selections.  When exiting box mode the box will be converted into multiple Atom selections that match the box.  This makes it easy to toggle back and forth while keeping the selection.

**Rectangular Atom Selections**  If you enter box mode, select a box inside of text, and exit, you will have created a rectangular selection of Atom cursors. This mimics other Atom rectangular selection tools.

**Selecting End Of Lines** You can put Atom cursors at the end of multiple lines by entering box mode, creating an empty box past the end of the lines, and exiting box mode.

**Box Editing** You can perform rectangular editing without leaving box mode. The following commands are supported in box mode.  At this time you cannot customize these bindings.

-  *Any Unicode Character:* Fill the box with the character.
-  *Ctrl-C:*  Copy the enclosed text into the clipboard as lines.
-  *Backspace or Delete:*  Delete the enclosed text and collapse the box.
-  *Ctrl-X:* Copy the text and then delete it.
-  *Ctrl-V:* Delete the text and insert the clipboard text.  The box will change width to match the longest line.
-  *Ctrl-A:* Surround the entire editing area with the box.
-  *Ctrl-Z:* Undo the last edit. Can only go back to when box mode was entered.
-  *Ctrl-Y:* Redo an edit.
-  *Enter:* Replace the red box with a green one that allows entering and editing wrapped text in a rectangle.  Uses an html textarea element.
-  *Escape or Tab:* If editing text in a green box then close the editor and go back to the red box.  If in normal red box mode then exit box mode altogether.
-  *Alt-S:* The command `box-edit:toggle` (not necessarily Alt-S) will close box mode.  It is useful in some situations to enter and exit quickly so pressing this key combo twice is an easy way to do it.
                
### Status: Beta

This has been used in my personal editor for a short while.  Use with caution.  Reports of satisfaction, good and bad, would be appreciated.  Email mark@hahnca.com or post problem reports to the issues section of https://github.com/mark-hahn/box-edit.
    
### Known Problems:

- After exiting box mode the cursor doesn't change back until the mouse moves.
    (apparently this is a chrome bug, a lot of people complain)

### To-Do 
          
- Add arrow-key support to allow keyboard-only selecting and editing.
          
### License

Copyright Mark Hahn using the MIT license
