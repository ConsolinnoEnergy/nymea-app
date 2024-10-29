function Component()
{
    gui.pageWidgetByObjectName("LicenseAgreementPage").entered.connect(changeLicenseLabels);
}

changeLicenseLabels = function()
{
    page = gui.pageWidgetByObjectName("LicenseAgreementPage");
    page.AcceptLicenseLabel.setText("Yes, I agree");
    page.RejectLicenseLabel.setText("No, I disagree");
}

Component.prototype.createOperations = function()
{
    component.createOperations();
    // return value 3010 means it need a reboot, but in most cases it is not needed for running Qt application
    // return value 5100 means there's a newer version of the runtime already installed

    component.addOperation("Execute", "{0,3010,1638,5100}", "@TargetDir@/vc_redist.x64.exe", "/quiet", "/norestart");
    if (systemInfo.productType === "windows") {
        component.addOperation("CreateShortcut", "@TargetDir@/Q.HOME-CONTROL.exe", "@StartMenuDir@/Q.HOME-CONTROL.lnk",
            "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/logo.ico",
            "description=Q.HOME CONTROL - frontend");

        component.addOperation("Execute", "reg", "add", "HKEY_CLASSES_ROOT\\Q.HOME-CONTROL", "/ve", "/d", "URL:Q.HOME-CONTROL", "/f");
        component.addOperation("Execute", "reg", "add", "HKEY_CLASSES_ROOT\\Q.HOME-CONTROL", "/v", "URL Protocol", "/f");
        component.addOperation("Execute", "reg", "add", "HKEY_CLASSES_ROOT\\Q.HOME-CONTROL\\shell\\open\\command", "/ve", "/d", "\"@TargetDir@//Q.HOME-CONTROL.exe\" \"%1\"", "/f");
    }
}
