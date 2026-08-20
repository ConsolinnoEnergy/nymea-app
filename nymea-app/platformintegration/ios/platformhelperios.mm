
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

#include <QDateTime>
#include <QFileInfo>
#include <QStandardPaths>
#include <QUrl>

#include <QtDebug>
#include <QtGlobal>
#include "logging.h"
#include "platformintegration/ios/platformhelperios.h"

NYMEA_LOGGING_CATEGORY(dcIOSPasswordPaste, "IOSPasswordPaste")

@interface NymeaDocumentPickerDelegate : NSObject <UIDocumentPickerDelegate>
@property(nonatomic, assign) PlatformHelperIOS *helper;
@end

static NymeaDocumentPickerDelegate *s_documentPickerDelegate = nil;

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

static UIViewController *activeViewController()
{
    UIWindow *window = activeWindow();
    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    return controller;
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

// #TODO Remove when Qt fixed QTBUG-146020
// -----------------------------------------------------------------------
// Crash guard for Qt's *internal, private* QIOSTapRecognizer class (see
// qtbase's src/plugins/platforms/ios/qiostextinputoverlay.mm - not part of
// any public Qt header; the class name and ivar name below are private
// implementation details of Qt and may change or disappear in any future
// Qt release without notice).
//
// Background (QTBUG-146020): QIOSTapRecognizer keeps a raw ivar
// "UIView *_focusView". When the user taps a text field to open the native
// edit menu, -touchesEnded:withEvent: schedules a dispatch_async() block on
// the main queue that later reads that *same ivar* (not a captured copy) and
// passes it to showEditMenu(). If -setEnabled:NO runs in between - which
// happens whenever focus moves away from the field - Qt releases and nils
// out _focusView synchronously, before the already-scheduled block runs.
// Qt's showEditMenu() does not nil-check its argument, so the pending block
// then crashes with a SIGSEGV.
//
// ESUI-1565 originally worked around this by disabling the whole text input
// overlay for password fields via Qt.ImhNoTextHandles, which also silently
// disabled pasting into those fields (ESUI-1615), since Qt's password
// fields are custom QML items and rely entirely on this overlay for
// copy/paste, unlike native UITextFields.
//
// To restore paste we instead close the actual race: we swizzle
// -setEnabled: so that, on the enabled->disabled transition, we do NOT let
// Qt release/nil _focusView synchronously. Instead we perform that exact
// teardown (and nothing else) one tick later, via dispatch_async() on the
// main queue. Because GCD's main queue is FIFO and any pending
// touchesEnded: block was necessarily scheduled *before* this -setEnabled:NO
// call (both run on the main thread, in call order), our deferred teardown
// is guaranteed to run *after* that pending block, so _focusView stays
// valid for its entire lifetime. We do not add any extra retain of our own:
// we simply delay the release that Qt's own code already owes from the
// matching retain it performed when the recognizer was enabled.
//
// This is written defensively throughout: every runtime lookup (class,
// selector, ivar) is checked at install time, and again in the swizzled
// function itself. On any mismatch we log a warning and fall back to
// calling Qt's original, unpatched implementation - i.e. we never guess
// about Qt's private internals, we bail out to the previously-shipped
// behaviour instead.
namespace {

IMP g_originalTapRecognizerSetEnabled = nullptr;
Ivar g_tapRecognizerFocusViewIvar = nullptr;

// Replacement for -[QIOSTapRecognizer setEnabled:]. Behaves identically to
// Qt's original implementation for every case except the enabled->disabled
// transition, where the final "release _focusView and set it to nil" step
// is deferred by one main-queue tick (see comment above) instead of
// happening synchronously.
void swizzled_tapRecognizer_setEnabled(id self, SEL _cmd, BOOL enabled)
{
    if (!g_originalTapRecognizerSetEnabled) {
        qCWarning(dcIOSPasswordPaste()) << "QTBUG-146020 guard: original QIOSTapRecognizer -setEnabled: implementation is missing; ignoring call to avoid undefined behaviour.";
        return;
    }

    typedef void (*SetEnabledFn)(id, SEL, BOOL);

    // Mirror Qt's own early-return ("if (enabled == self.enabled) return;")
    // so a redundant call never touches _focusView at all.
    const BOOL currentlyEnabled = [self isEnabled];
    if (enabled == currentlyEnabled) {
        return;
    }

    // Enabling (re-)establishes _focusView from scratch and is not part of
    // the race described above; call straight through to Qt's original code.
    if (enabled || !g_tapRecognizerFocusViewIvar) {
        ((SetEnabledFn) g_originalTapRecognizerSetEnabled)(self, _cmd, enabled);
        return;
    }

    // Disabling path: this is exactly the QTBUG-146020 race window.
    __unsafe_unretained UIView *focusView = (__bridge UIView *) object_getIvar(self, g_tapRecognizerFocusViewIvar);

    qCDebug(dcIOSPasswordPaste()) << "QTBUG-146020 guard: QIOSTapRecognizer disabling, deferring _focusView teardown by one runloop tick. focusView present:" << (focusView != nil);

    // Replicate Qt's own bookkeeping for "[super setEnabled:enabled]" so
    // UIGestureRecognizer's internal state stays consistent, exactly as Qt's
    // original code does - we just do it ourselves so we can hold back the
    // final release/nil of _focusView below.
    struct objc_super superInfo = { self, class_getSuperclass(object_getClass(self)) };
    typedef void (*SuperSetEnabledFn)(struct objc_super *, SEL, BOOL);
    ((SuperSetEnabledFn) objc_msgSendSuper)(&superInfo, _cmd, enabled);

    if (focusView) {
        [focusView removeGestureRecognizer:self];
    }

    // Explicitly keep `self` (the recognizer) alive across the dispatch gap
    // below, rather than relying on the block's default capture of `self`.
    // Whether a captured `id` is retained by a dispatched block's copy
    // helper differs between ARC and non-ARC compilation of this file - and
    // we do not know which applies here. Managing it ourselves via
    // CFRetain/CFRelease bridging is correct and safe under both, and avoids
    // reintroducing exactly the kind of use-after-free this guard exists to
    // prevent, just one level up (on the recognizer itself instead of its
    // focusView).
    CFRetain((__bridge CFTypeRef) self);

    dispatch_async(dispatch_get_main_queue(), ^{
        // By the time this runs, any touchesEnded: block that was already
        // pending on this same (FIFO) main queue before we got here has
        // executed and read a still-valid focusView.
        __unsafe_unretained UIView *stillCurrentFocusView = (__bridge UIView *) object_getIvar(self, g_tapRecognizerFocusViewIvar);
        if (stillCurrentFocusView != focusView) {
            // The recognizer was re-enabled (new focus view assigned) before
            // our deferred teardown ran; nothing to release here, releasing
            // the new view would be a double-release/use-after-free of its
            // own. Just log for visibility.
            qCDebug(dcIOSPasswordPaste()) << "QTBUG-146020 guard: focusView changed before deferred teardown ran (recognizer re-enabled); skipping release.";
            CFRelease((__bridge CFTypeRef) self);
            return;
        }

        if (focusView) {
            // CFRelease (rather than an explicit "-release" message) so this
            // compiles correctly whether or not this translation unit itself
            // is built with ARC; either way it performs the exact same
            // retain-count decrement Qt's own code would have done.
            CFRelease((__bridge CFTypeRef) focusView);
        }
        object_setIvar(self, g_tapRecognizerFocusViewIvar, nil);
        qCDebug(dcIOSPasswordPaste()) << "QTBUG-146020 guard: deferred _focusView teardown completed.";
        CFRelease((__bridge CFTypeRef) self);
    });
}

} // namespace

// #TODO Remove when Qt fixed QTBUG-146020
// Installs the crash guard above exactly once for the lifetime of the
// process. Safe to call multiple times. No-ops (with a warning) if Qt's
// private QIOSTapRecognizer class, its -setEnabled: method or its
// _focusView ivar cannot be found - e.g. because a future Qt release
// renamed, restructured or fixed the class - leaving Qt's own, unpatched
// behaviour in place rather than risking a crash from our own wrong
// assumptions about Qt's internals.
void PlatformHelperIOS::installPasswordPasteCrashGuard()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class tapRecognizerClass = NSClassFromString(@"QIOSTapRecognizer");
        if (!tapRecognizerClass) {
            qCWarning(dcIOSPasswordPaste()) << "QTBUG-146020 guard NOT installed: QIOSTapRecognizer class not found. Password field paste may still crash - keep Qt.ImhNoTextHandles as a fallback until this is investigated.";
            return;
        }

        SEL setEnabledSelector = @selector(setEnabled:);
        Method originalMethod = class_getInstanceMethod(tapRecognizerClass, setEnabledSelector);
        if (!originalMethod) {
            qCWarning(dcIOSPasswordPaste()) << "QTBUG-146020 guard NOT installed: QIOSTapRecognizer -setEnabled: not found.";
            return;
        }

        Ivar focusViewIvar = class_getInstanceVariable(tapRecognizerClass, "_focusView");
        if (!focusViewIvar) {
            qCWarning(dcIOSPasswordPaste()) << "QTBUG-146020 guard NOT installed: QIOSTapRecognizer _focusView ivar not found.";
            return;
        }

        g_tapRecognizerFocusViewIvar = focusViewIvar;
        g_originalTapRecognizerSetEnabled = method_setImplementation(originalMethod, (IMP) swizzled_tapRecognizer_setEnabled);
        if (!g_originalTapRecognizerSetEnabled) {
            qCWarning(dcIOSPasswordPaste()) << "QTBUG-146020 guard NOT installed: method_setImplementation failed unexpectedly.";
            g_tapRecognizerFocusViewIvar = nullptr;
            return;
        }

        qCInfo(dcIOSPasswordPaste()) << "QTBUG-146020 guard installed for QIOSTapRecognizer -setEnabled:.";
    });
}

static bool removeSandboxFileAtPath(NSString *path)
{
    if (!path) {
        return false;
    }

    NSString *homePath = NSHomeDirectory();
    if (!path || !homePath || ![path hasPrefix:[homePath stringByAppendingString:@"/"]]) {
        return false;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
        return false;
    }

    return [fileManager removeItemAtPath:path error:nil];
}

static bool removeSandboxFileAtPath(const QString &localPath)
{
    if (localPath.isEmpty()) {
        return false;
    }

    return removeSandboxFileAtPath(localPath.toNSString());
}

static QString localPathFromFileArgument(const QString &fileName)
{
    const QUrl url(fileName);
    return url.isLocalFile() ? url.toLocalFile() : fileName;
}

static void emitPickedFileUrl(PlatformHelperIOS *helper, NSURL *url)
{
    if (!helper) {
        return;
    }

    if (!url || !url.isFileURL) {
        emit helper->filePickError(QObject::tr("The selected file could not be accessed."));
        return;
    }

    const QString filePath = QString::fromNSString(url.path);
    if (filePath.isEmpty()) {
        emit helper->filePickError(QObject::tr("The selected file could not be accessed."));
        return;
    }

    emit helper->filePicked(QUrl::fromLocalFile(filePath), QFileInfo(filePath).fileName());
}

@implementation NymeaDocumentPickerDelegate

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    Q_UNUSED(controller)

    if (self.helper) {
        emit self.helper->filePickCanceled();
    }

    s_documentPickerDelegate = nil;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    Q_UNUSED(controller)

    PlatformHelperIOS *helper = self.helper;
    s_documentPickerDelegate = nil;

    emitPickedFileUrl(helper, urls.firstObject);
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    Q_UNUSED(controller)

    PlatformHelperIOS *helper = self.helper;
    s_documentPickerDelegate = nil;

    emitPickedFileUrl(helper, url);
}

@end

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

static void shareFileInternal(const QString &fileName, bool removeAfterSharing)
{
    const QString localPath = localPathFromFileArgument(fileName);
    if (localPath.isEmpty()) {
        return;
    }

    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:localPath.toNSString()]] applicationActivities:nil];
    UIViewController *qtController = activeViewController();
    if (!qtController) {
        if (removeAfterSharing) {
            removeSandboxFileAtPath(localPath);
        }
        return;
    }

    if (removeAfterSharing) {
        NSString *pathToRemove = [localPath.toNSString() copy];
        activityController.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            Q_UNUSED(activityType)
            Q_UNUSED(completed)
            Q_UNUSED(returnedItems)
            Q_UNUSED(activityError)
            removeSandboxFileAtPath(pathToRemove);
        };
    }

    UIPopoverPresentationController *popover = activityController.popoverPresentationController;
    if (popover) {
        UIView *sourceView = qtController.view ?: activeWindow();
        popover.sourceView = sourceView;
        popover.sourceRect = sourceView.bounds;
    }

    [qtController presentViewController:activityController animated:YES completion:nil];
}

void PlatformHelperIOS::shareFile(const QString &fileName)
{
    shareFileInternal(fileName, false);
}

bool PlatformHelperIOS::usesTemporaryExportFile() const
{
    return true;
}

QUrl PlatformHelperIOS::prepareTemporaryExportFile(const QString &fileName) const
{
    QString folder = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    if (folder.isEmpty()) {
        folder = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    }
    if (folder.isEmpty()) {
        return QUrl();
    }

    QString safeFileName = fileName.isEmpty() ? QStringLiteral("backup.tar.gz") : fileName;
    safeFileName = safeFileName.section(QLatin1Char('/'), -1).section(QLatin1Char('\\'), -1);
    if (safeFileName.isEmpty()) {
        safeFileName = QStringLiteral("backup.tar.gz");
    }

    safeFileName.prepend(QString::number(QDateTime::currentMSecsSinceEpoch()) + QLatin1Char('-'));
    return QUrl::fromLocalFile(folder + QLatin1Char('/') + safeFileName);
}

void PlatformHelperIOS::exportTemporaryFile(const QUrl &fileUrl)
{
    shareTemporaryFile(fileUrl.toString());
}

void PlatformHelperIOS::shareTemporaryFile(const QString &fileName)
{
    shareFileInternal(fileName, true);
}

void PlatformHelperIOS::removeFile(const QUrl &fileUrl)
{
    const QString localPath = fileUrl.isLocalFile() ? fileUrl.toLocalFile() : fileUrl.toString();
    removeSandboxFileAtPath(localPath);
}

bool PlatformHelperIOS::usesNativeFilePicker() const
{
    return true;
}

void PlatformHelperIOS::pickFile()
{
    UIViewController *qtController = activeViewController();
    if (!qtController) {
        emit filePickError(tr("The file picker is not available right now."));
        return;
    }

    if (s_documentPickerDelegate) {
        emit filePickError(tr("Another file picker is already open."));
        return;
    }

    UIDocumentPickerViewController *picker = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];
#pragma clang diagnostic pop
    picker.allowsMultipleSelection = NO;

    NymeaDocumentPickerDelegate *delegate = [[NymeaDocumentPickerDelegate alloc] init];
    delegate.helper = this;
    picker.delegate = delegate;
    s_documentPickerDelegate = delegate;

    UIPopoverPresentationController *popover = picker.popoverPresentationController;
    if (popover) {
        UIView *sourceView = qtController.view ?: activeWindow();
        popover.sourceView = sourceView;
        popover.sourceRect = sourceView.bounds;
    }

    [qtController presentViewController:picker animated:YES completion:nil];
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
