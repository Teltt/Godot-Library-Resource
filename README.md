# Godot-Library-Resource
A system for easily transfering code between projects
This addon purely uses the built in godot inspector. The library file should be named MANIFEST.tres and placed in the library folder
If a library resource isn't marked as external it will push an update to all project roots in external roots.
The library will be placed at the same path relative to the project root in all projects.
![image](https://github.com/user-attachments/assets/4f9d1665-522a-4cd3-b41d-e8e254cf739c)

If using an exported manifest, you can update all copies of the library in addition to the project's own by clicking the same button.

![image](https://github.com/user-attachments/assets/ea202340-3e94-4dd9-bf9d-bdf3190a4da1)

The classes with global names will be exported to a file like this, where the class name is the last folder in the library path



for example
extends Library.Example
