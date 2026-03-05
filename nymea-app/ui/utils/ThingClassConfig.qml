pragma Singleton
import QtQuick 2.15

QtObject {
    // ThingClass UUIDs where the name input field in the setup wizard should be hidden
    readonly property var nameFieldBlackList: [
        "68db705d-bc6a-42f0-8422-1e980d1330f0"  // SG Ready Interface + Zähler
    ]

    function isInNameFieldBlacklist(thingClassId) {
        var id = thingClassId.toString().replace(/[{}]/g, "")
        var blacklisted = nameFieldBlackList.indexOf(id) !== -1
        console.debug("ThingClassConfig", "ThingClass with id " + id + " is " + (blacklisted ? "" : "not") + " in NameField blacklist")

        return blacklisted
    }
}
