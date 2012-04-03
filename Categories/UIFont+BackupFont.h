//
//  UIFont+BackupFont.h
//  ipad
//
//  Created by Chris Haugli on 2/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

@interface UIFont (BackupFont)

// Returns the font with the specified name if available, otherwise returns the font with the backup font name.
+ (UIFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize backupFontName:(NSString *)backupFontName size:(CGFloat)backupFontSize;

@end
