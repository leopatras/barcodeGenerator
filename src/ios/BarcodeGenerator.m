#import "BarcodeGenerator.h"

@implementation BarcodeGenerator

- (void)barcodeGenerator:(CDVInvokedUrlCommand *)command
{
    NSString *text = [command.arguments firstObject];
    
    __block CDVPluginResult *pluginResult = nil;
    
    if (text == nil || [text length] == 0) {
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"text was empty."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    } else {
        
        NSData *data = [text dataUsingEncoding:NSASCIIStringEncoding];
        
        if (data == nil) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"can't generate barcode."];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
                [filter setValue:data forKey:@"inputMessage"];
                
                CIContext *context = [CIContext contextWithOptions:nil];
                CGImageRef cgImage = [context createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
                UIImage *barcodeImage = [[UIImage alloc] initWithCGImage:cgImage];
                
                NSData *imageData = UIImagePNGRepresentation(barcodeImage);
                NSString *base64String = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:base64String];
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            });
        }
    }
}

@end