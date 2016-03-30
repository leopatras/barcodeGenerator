
var BarcodeGeneratorPlugin = {
	generate: function(successCallback, errorCallback,text){
		cordova.exec(successCallback, errorCallback,'BarcodeGenerator','barcodeGenerator',[text])
	}
}

module.exports = BarcodeGeneratorPlugin;