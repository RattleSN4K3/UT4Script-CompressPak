CompressPak
==========================
A batch script to re-compress pak files

## Usage

- Install [this script](CompressPak.bat) into the root folder of your UE4 editor installation  
(or download and specify `CustomRoot` from the script file to point to the correct path)
- Drag and drop a _PAK file_ onto this script from the Windows Explorer  
(Note: this will overwrite the original file by default)
- Use the script as follows:  
    ```
# re-compress a single pak file
CompressPak.bat <file> [Options]
    ```

## Options:
<dl>
  <dt><code>-s</code></dt>
  <dd>Silent mode - Prevent any status message</dd>
  <dt><code>-o</code></dt>
  <dd>Overwrite - force to overwrite the original file</dd>
  <dt><code>-f</code></dt>
  <dd>Force - If option <code>-o</code> is not given, this will force to overwrite the new file if existing</dd>
  <dt><code>-u</code></dt>
  <dd>Uncompress - Uncompress the pak file instead of re-compressing it</dd>
</dl>

## License
Available under [the MIT license](http://opensource.org/licenses/mit-license.php).

## Author
RattleSN4K3
