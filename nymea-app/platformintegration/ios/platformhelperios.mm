
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

// Minimal view onto Qt's iOS text responder (QIOSTextInputResponder). We only
// need the two traits below and deliberately avoid importing the private Qt
// platform plugin header. Access is always guarded by -respondsToSelector:.
@protocol ConsoKeyboardAccessoryResponder <NSObject>
@property(nonatomic) UIKeyboardType keyboardType;
@property(readwrite, retain) UIView *inputAccessoryView;
@end

// Target for the accessory "dismiss" button. Bridges the UIKit tap to a C++
// callback. Kept memory-management agnostic (works under both ARC and MRC).
@interface ConsoKeyboardAccessoryTarget : NSObject
@property (nonatomic, copy) void (^onTap)(void);
- (void)tapped:(id)sender;
@end

@implementation ConsoKeyboardAccessoryTarget
- (void)tapped:(id)sender
{
    Q_UNUSED(sender);
    if (self.onTap) {
        self.onTap();
    }
}
@end

// The accessory bar is a single, app-lifetime instance shared across every
// numeric field, so it is intentionally created once and never released.
static UIToolbar *s_accessoryToolbar = nil;
static UIBarButtonItem *s_accessoryButton = nil;
static ConsoKeyboardAccessoryTarget *s_accessoryTarget = nil;

// Transiently set while walking the responder chain; read immediately after and
// never retained, so a plain (unsafe) pointer is correct under ARC and MRC.
static UIResponder *s_capturedFirstResponder = nil;

@interface UIResponder (ConsoFirstResponder)
- (void)conso_captureFirstResponder:(id)sender;
@end

@implementation UIResponder (ConsoFirstResponder)
- (void)conso_captureFirstResponder:(id)sender
{
    Q_UNUSED(sender);
    s_capturedFirstResponder = self;
}
@end

static UIResponder *consoCurrentFirstResponder()
{
    s_capturedFirstResponder = nil;
    // Sending an action to a nil target delivers it to the current first
    // responder, which captures itself. This is the standard UIKit idiom and
    // mirrors Qt's own +[UIResponder qt_currentFirstResponder].
    [[UIApplication sharedApplication] sendAction:@selector(conso_captureFirstResponder:)
                                               to:nil
                                             from:nil
                                         forEvent:nil];
    return s_capturedFirstResponder;
}

static BOOL consoIsNumericKeyboardType(UIKeyboardType type)
{
    // These pad layouts have no return key, so the user cannot dismiss the
    // keyboard from the keyboard itself - hence the accessory bar.
    switch (type) {
    case UIKeyboardTypeNumberPad:
    case UIKeyboardTypePhonePad:
    case UIKeyboardTypeDecimalPad:
    case UIKeyboardTypeASCIICapableNumberPad:
        return YES;
    default:
        return NO;
    }
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
        // Keep the numeric-keyboard dismiss bar in sync with the current
        // responder. Attaching it here (and calling reloadInputViews) makes the
        // keyboard frame grow by the bar's height, which re-fires this
        // notification so imeHeight below already accounts for the bar.
        this->updateKeyboardAccessory();

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

void PlatformHelperIOS::updateKeyboardAccessory()
{
    UIResponder *responder = consoCurrentFirstResponder();
    if (!responder
        || ![responder respondsToSelector:@selector(keyboardType)]
        || ![responder respondsToSelector:@selector(inputAccessoryView)]
        || ![responder respondsToSelector:@selector(setInputAccessoryView:)]) {
        return;
    }

    id<ConsoKeyboardAccessoryResponder> textResponder = (id<ConsoKeyboardAccessoryResponder>)responder;
    const BOOL wantBar = consoIsNumericKeyboardType(textResponder.keyboardType);

    // Build the shared accessory bar lazily, the first time a numeric field is
    // focused. imeActionButtonText has been provided by QML (translated) well
    // before this point.
    if (wantBar && !s_accessoryToolbar) {
        PlatformHelperIOS *helper = this;

        s_accessoryTarget = [[ConsoKeyboardAccessoryTarget alloc] init];
        s_accessoryTarget.onTap = ^{
            // Runs on the main thread == Qt's GUI thread on iOS, so notifying
            // QML synchronously is safe. QML hides the input panel and drops
            // focus so the keyboard is not immediately reopened.
            emit helper->imeActionTriggered();
        };

        s_accessoryButton = [[UIBarButtonItem alloc] initWithTitle:helper->imeActionButtonText().toNSString()
                                                             style:UIBarButtonItemStyleDone
                                                            target:s_accessoryTarget
                                                            action:@selector(tapped:)];
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];

        s_accessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        s_accessoryToolbar.items = @[flexSpace, s_accessoryButton];
        [s_accessoryToolbar sizeToFit];
    }

    UIView *current = textResponder.inputAccessoryView;
    if (wantBar) {
        if (current != s_accessoryToolbar) {
            textResponder.inputAccessoryView = s_accessoryToolbar;
            [responder reloadInputViews];
        }
    } else if (s_accessoryToolbar && current == s_accessoryToolbar) {
        textResponder.inputAccessoryView = nil;
        [responder reloadInputViews];
    }
}

void PlatformHelperIOS::setImeActionButtonText(const QString &text)
{
    PlatformHelper::setImeActionButtonText(text);
    if (s_accessoryButton) {
        s_accessoryButton.title = text.toNSString();
    }
}
