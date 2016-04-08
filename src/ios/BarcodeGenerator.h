#import <Cordova/CDV.h>

typedef void (^GenerateBarcodeCompletion) (NSString *base64string, NSError *error);

@interface BarcodeGenerator : CDVPlugin

- (void)barcodeGenerator:(CDVInvokedUrlCommand *)command;

- (UIImage *)createImageFromText:(NSString *)text size:(CGSize)size color:(UIColor *)color andBackgroundColor:(UIColor *)backgroundColor withCompletion:(GenerateBarcodeCompletion)completion;

@end
