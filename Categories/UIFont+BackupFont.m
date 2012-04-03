//
//  UIFont+BackupFont.m
//  ipad
//
//  Created by Chris Haugli on 2/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "UIFont+BackupFont.h"

@implementation UIFont (BackupFont)

+ (UIFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize backupFontName:(NSString *)backupFontName size:(CGFloat)backupFontSize
{
    UIFont *font = [self fontWithName:fontName size:fontSize];
    if (!font) {
        font = [self fontWithName:backupFontName size:backupFontSize];
    }
    
    return font;
}

@end
