
var BarcodeGeneratorPlugin = {
	generate: function(successCallback, errorCallback,text,height,width,color,bgColor){
    		cordova.exec(successCallback, errorCallback,'BarcodeGenerator','barcodeGenerator',[text,height,width,color,bgColor])
    	}
}

module.exports = BarcodeGeneratorPlugin;