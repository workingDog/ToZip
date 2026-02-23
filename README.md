#  ToZip

A very basic SwiftUI app to convert a text file (or any other file type) to a password protected ZIP file.

The ZIP file is encrypted using the ZIP compatible AES-256 encryption.

AES-256 ZIP with a long random password is remarkably very secure.

<p float="left">
  <img src="picture1.png" width="300" height="400" /> 
  <img src="picture2.png" width="300" height="400" /> 
</p>


### Usage

On a Mac, drag and drop a file into the app, or select the **Browse for File** option.
On ios devices, the app ask the user to **Browse for File** only.

A password for the ZIP file is then asked for. 

The app writes the input file into a AES-256 password protected ZIP file. 
The user choose where to store the resulting ZIP file.

The created zip file can be unzipped back to the original type by common zip app, 
such as: 7-Zip, WinZip, etc...

On a Mac or iOS devices, simply double-click the .zip file; a system dialog pops up asking for the required password.

My original requirement was for input *text* files only, 
but can now be used for any types, such as: text, image, pdf, etc...

### Reference

The app uses the following ZipArchive library:

[SSZipArchive](https://github.com/ZipArchive/ZipArchive) a simple utility class for zipping and unzipping files on iOS, macOS, tvOS, watchOS and visionOS.

