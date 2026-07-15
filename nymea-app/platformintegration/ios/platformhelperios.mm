
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>

#include <QtDebug>
#include <QtGlobal>
#include "platformintegration/ios/platformhelperios.h"

static UIWindow *activeWindow()
{
    UIApplication *application = [UIApplication sharedApplication];
    UIWindow *window = application.keyWindow;
    if (window) {
        return window;
    }

    for (UIWindow *candidate in application.windows) {
        if (candidate.isKeyWindow) {
            return candidate;
        }
    }

    return application.windows.firstObject;
}

static CGRect statusBarFrameForWindow(UIWindow *window)
{
    if (!window) {
        return CGRectZero;
    }

    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = window.windowScene.statusBarManager;
        if (statusBarManager) {
            CGRect frame = statusBarManager.statusBarFrame;
            if (!CGRectIsEmpty(frame)) {
                return frame;
            }
        }
        CGFloat height = window.safeAreaInsets.top;
        return CGRectMake(0, 0, window.bounds.size.width, height);
    }

    return [UIApplication sharedApplication].statusBarFrame;
}

QString PlatformHelperIOS::deviceName() const
{
    NSString *const name = UIDevice.currentDevice.name;
    if (!name) {
        return QString();
    }
    return QString::fromNSString(name).trimmed();
}

QString PlatformHelperIOS::readKeyChainEntry(const QString &service, const QString &key)
{
    NSDictionary *const query = @{
        (__bridge id) kSecClass: (__bridge id) kSecClassGenericPassword,
            (__bridge id) kSecAttrService: (__bridge NSString *) service.toCFString(),
            (__bridge id) kSecAttrAccount: (__bridge NSString *) key.toCFString(),
            (__bridge id) kSecReturnData: @YES,
    };

    CFTypeRef dataRef = nil;
    const OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, &dataRef);

    QByteArray data;
    if (status == errSecSuccess) {
        if (dataRef)
            data = QByteArray::fromCFData((CFDataRef) dataRef);

    } else {
        qWarning() << "Error accessing keychain value" << status;
    }

    if (dataRef)
        CFRelease(dataRef); // SecItemCopyMatching creates a retained object; release with CFRelease.

    return data;
}

void PlatformHelperIOS::writeKeyChainEntry(const QString &service, const QString &key, const QString &value)
{
    NSDictionary *const query = @{
            (__bridge id) kSecClass: (__bridge id) kSecClassGenericPassword,
            (__bridge id) kSecAttrService: (__bridge NSString *) service.toCFString(),
            (__bridge id) kSecAttrAccount: (__bridge NSString *) key.toCFString(),
    };

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, nil);

    if (status == errSecSuccess) {
        NSDictionary *const update = @{
                (__bridge id) kSecValueData: (__bridge NSData *) value.toUtf8().toCFData(),
        };

        status = SecItemUpdate((__bridge CFDictionaryRef) query, (__bridge CFDictionaryRef) update);
    } else {
        NSDictionary *const insert = @{
                (__bridge id) kSecClass: (__bridge id) kSecClassGenericPassword,
                (__bridge id) kSecAttrService: (__bridge NSString *) service.toCFString(),
                (__bridge id) kSecAttrAccount: (__bridge NSString *) key.toCFString(),
                (__bridge id) kSecValueData: (__bridge NSData *) value.toUtf8().toCFData(),
        };

        status = SecItemAdd((__bridge CFDictionaryRef) insert, nil);
    }

    if (status == errSecSuccess) {
        qDebug() << "Successfully stored value in keychain";
    } else {
        qWarning() << "Error storing value in keycahin" << status;
    }
}


void PlatformHelperIOS::generateSelectionFeedback()
{
    UISelectionFeedbackGenerator *generator = [[UISelectionFeedbackGenerator alloc] init];
    [generator prepare];
    [generator selectionChanged];
    generator = nil;
}

void PlatformHelperIOS::generateImpactFeedback()
{
    // UIImpactFeedbackStyleLight
    // UIImpactFeedbackStyleMedium
    // UIImpactFeedbackStyleHeavy
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [generator prepare];
    [generator impactOccurred];
    generator = nil;
}

void PlatformHelperIOS::generateNotificationFeedback()
{
//    UINotificationFeedbackTypeSuccess
//    UINotificationFeedbackTypeWarning
//    UINotificationFeedbackTypeError

    UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
    [generator prepare];
    [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
    generator = nil;
}

void PlatformHelperIOS::setTopPanelColorInternal(const QColor &color)
{
    UIWindow *window = activeWindow();
    if (!window) {
        return;
    }

    static const NSInteger statusBarViewTag = 0x6E796D; // "nym" to avoid clashes
    UIColor *uiColor = [UIColor colorWithRed:color.redF() green:color.greenF() blue:color.blueF() alpha:color.alphaF()];
    CGRect frame = statusBarFrameForWindow(window);
    UIView *statusBar = [window viewWithTag:statusBarViewTag];
    if (statusBar) {
        statusBar.frame = frame;
    } else {
        statusBar = [[UIView alloc] initWithFrame:frame];
        statusBar.tag = statusBarViewTag;
        statusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [window addSubview:statusBar];
    }
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = uiColor;
    }
    [window bringSubviewToFront:statusBar];

    if (((color.red() * 299 + color.green() * 587 + color.blue() * 114) / 1000) > 123) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDarkContent animated:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }
}

void PlatformHelperIOS::setBottomPanelColorInternal(const QColor &color)
{
    //Bottom
    UIColor *uiColor = [UIColor colorWithRed:color.redF() green:color.greenF() blue:color.blueF() alpha:color.alphaF()];
    UIWindow *window = activeWindow();
    if (!window) {
        return;
    }

    window.backgroundColor = uiColor;
    if (window.rootViewController && window.rootViewController.view) {
        window.rootViewController.view.backgroundColor = uiColor;
    }
}

bool PlatformHelperIOS::darkModeEnabled() const
{
    if (@available(iOS 12.0, *)) {
        return UIScreen.mainScreen.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    return false;
}

void PlatformHelperIOS::shareFile(const QString &fileName)
{
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:fileName.toNSString()]] applicationActivities:nil];
    UIViewController *qtController = [[UIApplication sharedApplication].keyWindow rootViewController];
    [qtController presentViewController:activityController animated:YES completion:nil];
}

void PlatformHelperIOS::updateSafeAreaPadding()
{
    UIWindow *window = activeWindow();
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (window) {
        if (@available(iOS 11.0, *)) {
            insets = window.safeAreaInsets;
        } else {
            CGRect statusFrame = statusBarFrameForWindow(window);
            insets.top = statusFrame.size.height;
        }
    }
    setSafeAreaPadding(qRound(insets.top), qRound(insets.right), qRound(insets.bottom), qRound(insets.left));
}

void PlatformHelperIOS::setupKeyboardObservers()
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    // Fires for keyboard show, hide and any frame change (keyboard type
    // switches, autocorrect bar, interactive drag-to-dismiss). We always
    // recompute from the reported end frame.
    [center addObserverForName:UIKeyboardWillChangeFrameNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
        NSValue *frameValue = note.userInfo[UIKeyboardFrameEndUserInfoKey];
        if (!frameValue) {
            return;
        }

        UIWindow *window = activeWindow();
        if (!window) {
            return;
        }

        // The keyboard end frame is given in screen coordinates. Convert it
        // into the window's coordinate space and intersect it with the window
        // bounds so we only account for the part of the keyboard that actually
        // overlaps the app content. This keeps split/floating keyboards, the
        // hardware-keyboard accessory bar and multi-window (Stage Manager)
        // layouts on iPad correct.
        CGRect keyboardFrameScreen = [frameValue CGRectValue];
        CGRect keyboardFrameInWindow = [window convertRect:keyboardFrameScreen fromWindow:nil];
        CGRect overlapRect = CGRectIntersection(window.bounds, keyboardFrameInWindow);
        CGFloat overlap = CGRectIsNull(overlapRect) ? 0.0 : overlapRect.size.height;

        // UIKit works in points, which map 1:1 onto Qt's device independent
        // pixels on iOS (QWindow/QScreen geometry is expressed in points there,
        // with devicePixelRatio carrying the retina scale factor).
        // PlatformHelper::imeHeight is likewise a device-independent-pixel
        // value, so the point value is passed straight through.
        //
        // IMPORTANT: unlike the Android bridge - which receives *physical*
        // pixels from WindowInsets and therefore divides by devicePixelRatio -
        // we must NOT scale here. Dividing by devicePixelRatio would report a
        // keyboard height that is 2-3x too small on retina devices. This
        // mirrors updateSafeAreaPadding(), which also forwards UIKit points
        // unscaled.
        this->setImeHeight(qRound(overlap));
    }];

    // Guarantee a return to zero once the keyboard is fully dismissed.
    [center addObserverForName:UIKeyboardWillHideNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *) {
        this->setImeHeight(0);
    }];
}
