// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef LIBNYMEA_APP_RFID_H
#define LIBNYMEA_APP_RFID_H

#include "rfidmanager.h"
#include "rfidtaginfo.h"
#include "rfidtags.h"

#include <qqml.h>

namespace Nymea {
namespace Rfid {

void registerQmlTypes()
{
    const char uri[] = "Nymea.Rfid";
    qmlRegisterType<RfidManager>(uri, 1, 0, "RfidManager");
    qmlRegisterUncreatableType<RfidTags>(uri, 1, 0, "RfidTags", "Get it from RfidManager");
    qmlRegisterUncreatableType<RfidTagInfo>(uri, 1, 0, "RfidTagInfo", "Get it from RfidTags");
}

}
}

#endif // LIBNYMEA_APP_RFID_H
