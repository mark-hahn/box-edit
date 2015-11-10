
## box-edit

An Atom package to edit rectangular areas; supports short lines..

Box-edit provides for selecting and editing a box (rectangular area) of text in the Atom editor. When in box mode the Atom cursors disappear and a new red box cursor takes over.  You can cut, paste, insert, etc., on a box instead of character strings. Box-edit supports virtual spaces to the right of lines which solves a problem found in line-cursor-based rectangular selection tools.

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

**Selecting** When in box mode you can select a box by clicking and dragging the mouse. The box will be shown as a red rectangle.  The support of arrow keys is planned for the future.  You may select anywhere in the editor pane including to the right of line endings.

**Single Clicking** If you click without dragging then a zero-width box  will be created. This is useful before inserting a box.  You can also extend it to a bigger box using shift-click. 

**Extending Selection** Shift-click will move the second corner of a box to the new point. This allows extending a selection. If you wish to create a box that is taller/wider than the current screen then you must select one corner with a single-click, scroll the pane, and then shift-click to set the second corner.

**Atom Selection Matching** When you enter box-mode a new box will be created that surrounds all existing Atom selections.  When exiting box mode the box will be converted into multiple Atom selections that match the box.  This makes it easy to toggle back and forth while keeping the selection.

**Rectangular Atom Selections**  If you enter box mode, select a box, and exit, you will have created a rectangular selection of Atom cursors. This mimics other Atom rectangular selection tools.

**Box Editing** You can perform rectangular editing without leaving box mode. The current list of commands are 

**Box Editing** You can perform rectangular editing without leaving box mode. The following commands are supported in box mode.  At this time you cannot customize these bindings.

-  *Any Unicode Character:* Fill the box with the character.
-  *Ctrl-C:*  Copy the enclosed text into the clipboard as lines.
-  *Backspace or Delete:*  Delete the enlosed text and collapse the box.
-  *Ctrl-X:* Copy the text and then delete it.
-  *Ctrl-V:* Delete the text and insert the clipboard text.  The box will change width to match the longest line.
-  *Ctrl-A:* Surround the entire editing area with the box.
-  *Ctrl-Z:* Undo the last edit. Can only go back to when box mode was entered.
-  *Ctrl-Y:* Redo an edit.
-  *Enter:* Replace the red box with a green one that allows entering and editing text in a rectangle.  Uses an html textarea element.
-  *Escape or Tab:* If editing text in a green box then close the editor and go back to the red box.  If in normal red box mode then exit box mode altogether.
                    
### To-Do 
          
- Add arrow-key support to allow keyboard-only selecting and editing.
          
### Known Problems:
- Wrap problems when shrinking page
- Mouse cursor doesn't change until mouse moves
          
### License
Copyright Mark Hahn using the MIT license
