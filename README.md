# Barcode Generator
##Compatible

Android Version <= 4.0

iOS Version >= 8.0

###This plugin is generate only Barcode type 128

##How to install.
* Use this code in command line.<br/>
`cordova plugin add cordova-barcode-generator`

Done!

##How to use.
``````
in *.js that you want to use this.
var success = function(message) { alert(message); };
var error = function(message) { alert("Oopsie! " + message); };
var barcode = cordova.require("com.attendee.barcodegenerator.BarcodeGenerator");
barcode.generate(success,error,"12345");
The plugin will return base64 string of barcode image for using in cordova.
``````