
## box-edit

An Atom package to edit rectangular areas; supports short lines..

Box-edit provides for selecting and editing a box (rectangular area) of text in the Atom editor. When in box mode the Atom cursors disappear and a new box cursor takes over.  You can cut, paste, insert, etc., on a box instead of character strings. Box-edit supports virtual spaces to the right of lines which solves a problem found in line-cursor-based rectangular selection tools.

### Features

- A box can be selected, cut, and pasted anywhere, even to the right of lines.
- Supports wrapped lines properly.
- The box can be filled with any character, such as a space, to blank an area.
- The box mode supports basic editor commands such as cut, copy, paste, and undo/redo.
- A box can be turned into a character-based editor (an html textarea) which allows typing wrapped text into a rectangle.  Useful for comments to the right of multiple lines.
- When opening a box, Atom cursors are converted into a box, and when closing the box it is converted back into Atom selections. So by switching back and forth you can create Atom cursor-based rectangles like other packages do.

### To-Do

- Add arrow-key support to allow keyboard-only selecting and editing.

### Known Problems:
  wrap problems when shrinking page
  cursor doesn't change until mouse moves
  
### License
Copyright Mark Hahn using the MIT license
