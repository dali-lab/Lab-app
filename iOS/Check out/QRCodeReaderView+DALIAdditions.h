//
//  QRCodeReaderView+DALIAdditions.h
//  DALI Lab
//
//  Created by John Kotz on 9/17/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

#import <QRCodeReaderViewController/QRCodeReaderViewController.h>
#import <QRCodeReaderViewController/QRCodeReaderView.h>

NS_ASSUME_NONNULL_BEGIN

@interface QRCodeReaderView (DALIAdditions)

@property (nonatomic) CAShapeLayer *overlay;

@end

NS_ASSUME_NONNULL_END
