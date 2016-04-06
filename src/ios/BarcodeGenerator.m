#import "BarcodeGenerator.h"

@implementation BarcodeGenerator

- (void)barcodeGenerator:(CDVInvokedUrlCommand *)command
{
    NSString *text = [command.arguments objectAtIndex:0]; // Text
    NSInteger height = [[command.arguments objectAtIndex:1] integerValue]; //Height
    NSInteger width = [[command.arguments objectAtIndex:2] integerValue]; //Width
    
    UIColor *barcodeColor;
    UIColor *backgroundColor;

    id colorString = [command.arguments objectAtIndex:3]; //Barcode Color
    barcodeColor = (colorString != [NSNull null])?[self colorWithHexString:colorString]:nil;
    
    id backgroundColorString = [command.arguments objectAtIndex:4]; //Background Color
    backgroundColor = (backgroundColorString != [NSNull null])?[self colorWithHexString:backgroundColorString]:nil;
    

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
                
                UIImage *img = [self createImageFrom:filter.outputImage size:CGSizeMake(width, height) color:barcodeColor andBackgroundColor:backgroundColor];
                
                NSData *imageData = UIImagePNGRepresentation(img);
                NSString *base64String = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:base64String];
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            });
        }
    }
}

- (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}


- (UIImage *)createImageFrom:(CIImage *)image size:(CGSize)size color:(UIColor *)color andBackgroundColor:(UIColor *)backgroundColor {
    
    if (!color) {
        color = [UIColor blackColor];
    }
    
    if (!backgroundColor) {
        backgroundColor = [UIColor whiteColor];
    }
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = [UIScreen mainScreen].scale;
    size_t width = size.width * scale;
    size_t height = size.height * scale;
    
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    
    CGImageRef actualMask = CGImageMaskCreate(CGImageGetWidth(bitmapImage),
                                              CGImageGetHeight(bitmapImage),
                                              CGImageGetBitsPerComponent(bitmapImage),
                                              CGImageGetBitsPerPixel(bitmapImage),
                                              CGImageGetBytesPerRow(bitmapImage),
                                              CGImageGetDataProvider(bitmapImage),
                                              NULL, false);
    
    CGImageRef imgRef = CGImageCreateWithMask(bitmapImage, actualMask);
    CGImageRelease(actualMask);
    CGImageRelease(bitmapImage);
    
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             width,
                                             height,
                                             8,
                                             0,
                                             cs,
                                             kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(cs);
    
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextDrawImage(ctx, rect, imgRef);
    
    if (nil != color) {
        CGContextSetBlendMode(ctx, kCGBlendModeSourceIn);
        CGContextSetFillColorWithColor(ctx, color.CGColor);
        CGContextFillRect(ctx, rect);
    }
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(ctx);
    CGImageRelease(imgRef);
    CGContextRelease(ctx);
    
    UIImage *img = [UIImage imageWithCGImage:scaledImage scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(scaledImage);
    
    CGRect newRect = CGRectMake(0, 0, width, height);
    
    UIGraphicsBeginImageContext(newRect.size);
    CGContextRef newContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(newContext);
    
    [backgroundColor setFill];
    
    CGContextFillRect(newContext, newRect);
    
    [img drawInRect:newRect];
    
    UIImage *rawImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage *finalImage = [UIImage imageWithCGImage:rawImage.CGImage scale:scale orientation:UIImageOrientationUp];
    
    return finalImage;
}


@end
