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
        component.addOperation("CreateShortcut", "@TargetDir@/Zewo-Dynamics.exe", "@StartMenuDir@/Zewo-Dynamics.lnk",
            "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/logo.ico",
            "description=Zewo-Dynamics - frontend");

        component.addOperation("Execute", "reg", "add", "HKEY_CLASSES_ROOT\\Zewo-Dynamics", "/ve", "/d", "URL:Zewo-Dynamics", "/f");
        component.addOperation("Execute", "reg", "add", "HKEY_CLASSES_ROOT\\Zewo-Dynamics", "/v", "URL Protocol", "/f");
        component.addOperation("Execute", "reg", "add", "HKEY_CLASSES_ROOT\\Zewo-Dynamics\\shell\\open\\command", "/ve", "/d", "\"@TargetDir@//Zewo-Dynamics.exe\" \"%1\"", "/f");
    }
}
