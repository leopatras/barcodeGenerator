#import "BarcodeGenerator.h"

@implementation BarcodeGenerator

#pragma mark - Convert HEX to UIColor
/*
    Source: http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
 */

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
            
            return nil;
            
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

#pragma mark - Plugin connector

- (void)barcodeGenerator:(CDVInvokedUrlCommand *)command
{
    UIColor *barcodeColor;
    UIColor *backgroundColor;
    
    id textArg = [command.arguments objectAtIndex:0];
    
    NSString *text = nil; // Text
    
    if (![textArg isKindOfClass:[NSString class]]) {
        text = [[command.arguments objectAtIndex:0] stringValue];
    } else {
        text  = [command.arguments objectAtIndex:0];
    }
    
    NSInteger height = [[command.arguments objectAtIndex:1] integerValue]; //Height
    NSInteger width  = [[command.arguments objectAtIndex:2] integerValue]; //Width

    id colorString           = [command.arguments objectAtIndex:3]; //Barcode Color
    barcodeColor             = (colorString != [NSNull null])?[self colorWithHexString:colorString]:nil;

    id backgroundColorString = [command.arguments objectAtIndex:4]; //Background Color
    backgroundColor          = (backgroundColorString != [NSNull null])?[self colorWithHexString:backgroundColorString]:nil;
    
    __block CDVPluginResult *pluginResult = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createImageFromText:text size:(CGSizeMake(width, height)) color:barcodeColor andBackgroundColor:backgroundColor withCompletion:^(NSString *base64string, NSError *error) {
            
            if (error) {
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedFailureReason];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:base64string];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    });
}

#pragma mark - Generate Barcode

- (UIImage *)createImageFromText:(NSString *)text size:(CGSize)size color:(UIColor *)color andBackgroundColor:(UIColor *)backgroundColor withCompletion:(GenerateBarcodeCompletion)completion {
    
    //Check iOS version more than 8.0 if not can not generate barcode.
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                             code:-1
                                         userInfo:@{NSLocalizedFailureReasonErrorKey: @"can't generate barcode."}];
        completion(nil, error);
        
    } else if (text == nil || [text length] == 0) {
        
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                             code:-1
                                         userInfo:@{NSLocalizedFailureReasonErrorKey: @"text was empty."}];
        completion(nil, error);
        
    } else {
        
        NSData *data = [text dataUsingEncoding:NSASCIIStringEncoding];
        
        if (data == nil) {
            
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                 code:-1
                                             userInfo:@{NSLocalizedFailureReasonErrorKey: @"can't generate barcode."}
                              ];
            completion(nil, error);
            
        } else {
            
            CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
            [filter setValue:data forKey:@"inputMessage"];
//            [filter setValue:@0 forKey:@"inputQuietSpace"]; //Change white space.
            
            if (!color) { //If no color set to Black.
                color = [UIColor blackColor];
            }
            
            if (!backgroundColor) { //If no color set to White.
                backgroundColor = [UIColor whiteColor];
            }
            
            CGRect extent = CGRectIntegral(filter.outputImage.extent);
            CGFloat scale = [UIScreen mainScreen].scale;
            size_t width = size.width;// * scale;
            size_t height = size.height;// * scale;
            
            CIContext *context = [CIContext contextWithOptions:nil];
            
            CGImageRef bitmapImage = [context createCGImage:filter.outputImage fromRect:extent];
            
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
            
            //Generate Barcode Bitmap
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
            
            CGContextSetBlendMode(ctx, kCGBlendModeSourceIn);
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillRect(ctx, rect);
            
            CGImageRef colorImage = CGBitmapContextCreateImage(ctx);
            CGImageRelease(imgRef);
            CGContextRelease(ctx);
            
            //Generate Barcode Background Bitmap
            
            CGColorSpaceRef backgroundcs = CGColorSpaceCreateDeviceRGB();
            CGContextRef backgroundContextRef = CGBitmapContextCreate(NULL,
                                                                      width,
                                                                      height,
                                                                      8,
                                                                      0,
                                                                      backgroundcs,
                                                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
            
            CGColorSpaceRelease(backgroundcs);
            
            CGContextSetInterpolationQuality(backgroundContextRef, kCGInterpolationNone);
            
            CGContextSetFillColorWithColor(backgroundContextRef, backgroundColor.CGColor);
            CGContextFillRect(backgroundContextRef, rect);
            
            CGContextDrawImage(backgroundContextRef, rect, colorImage);
            
            CGImageRef scaledImage = CGBitmapContextCreateImage(backgroundContextRef);
            
            CGImageRelease(colorImage);
            CGContextRelease(backgroundContextRef);
            
            UIImage *img = [UIImage imageWithCGImage:scaledImage scale:scale orientation:UIImageOrientationUp];
            CGImageRelease(scaledImage);
            
            NSData *imageData = UIImagePNGRepresentation(img);
            NSString *base64String = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            completion(base64String, nil);
            
            return img;
        }
    }
    
    return nil;
}

@end
