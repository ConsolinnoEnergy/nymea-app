/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright 2013 - 2020, nymea GmbH
* Contact: contact@nymea.io
*
* This file is part of nymea.
* This project including source code and documentation is protected by
* copyright law, and remains the property of nymea GmbH. All rights, including
* reproduction, publication, editing and translation, are reserved. The use of
* this project is subject to the terms of a license agreement to be concluded
* with nymea GmbH in accordance with the terms of use of nymea GmbH, available
* under https://nymea.io/license
*
* GNU General Public License Usage
* Alternatively, this project may be redistributed and/or modified under the
* terms of the GNU General Public License as published by the Free Software
* Foundation, GNU version 3. This project is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along with
* this project. If not, see <https://www.gnu.org/licenses/>.
*
* For any further details and any questions please contact us under
* contact@nymea.io or see our FAQ/Licensing Information on
* https://nymea.io/license/faq
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "tagsproxymodel.h"
#include "engine.h"
#include "tagsmanager.h"
#include "types/tag.h"

#include <QLoggingCategory>
Q_DECLARE_LOGGING_CATEGORY(dcTags)

TagsProxyModel::TagsProxyModel(QObject *parent) : QSortFilterProxyModel(parent)
{
}

Tags *TagsProxyModel::tags() const
{
    return m_tags;
}

void TagsProxyModel::setTags(Tags *tags)
{
    if (m_tags != tags) {
        m_tags = tags;
        setSourceModel(tags);
        connect(tags, &Tags::countChanged, this, [=](){
            invalidateFilter();
            emit countChanged();
        }, Qt::QueuedConnection);
        connect(tags, &Tags::dataChanged, this, [=](){
            emit countChanged();
        }, Qt::QueuedConnection);
        setSortRole(Tags::RoleValue);
        sort(0);
        emit tagsChanged();
        emit countChanged();
    }
}

QString TagsProxyModel::filterTagId() const
{
    return m_filterTagId;
}

void TagsProxyModel::setFilterTagId(const QString &filterTagId)
{
    if (m_filterTagId != filterTagId) {
        m_filterTagId = filterTagId;
        emit filterTagIdChanged();
        invalidateFilter();
        emit countChanged();
    }
}

QUuid TagsProxyModel::filterThingId() const
{
    return m_filterThingId;
}

void TagsProxyModel::setFilterThingId(const QUuid &filterThingId)
{
    if (m_filterThingId != filterThingId) {
        m_filterThingId = filterThingId;
        emit filterThingIdChanged();
        invalidateFilter();
        emit countChanged();
    }
}

QUuid TagsProxyModel::filterRuleId() const
{
    return m_filterRuleId;
}

void TagsProxyModel::setFilterRuleId(const QUuid &filterRuleId)
{
    if (m_filterRuleId != filterRuleId) {
        m_filterRuleId = filterRuleId;
        emit filterRuleIdChanged();
        invalidateFilter();
        emit countChanged();
    }
}

QString TagsProxyModel::filterValue() const
{
    return m_filterValue;
}

void TagsProxyModel::setFilterValue(const QString &filterValue)
{
    if (m_filterValue != filterValue) {
        m_filterValue = filterValue;
        emit filterValueChanged();
        invalidateFilter();
        emit countChanged();
    }
}

Tag *TagsProxyModel::get(int index) const
{
    if (index < 0 || index > rowCount()) {
        return nullptr;
    }
    return m_tags->get(mapToSource(this->index(index, 0)).row());
}

Tag *TagsProxyModel::findTag(const QString &tagId) const
{
    for (int i = 0; i < rowCount(); i++) {
        Tag *tag = m_tags->get(mapToSource(index(i, 0)).row());
        if (tag->tagId() == tagId) {
            return tag;
        }
    }
    return nullptr;
}

bool TagsProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    Q_UNUSED(source_parent)
    Tag *tag = m_tags->get(source_row);
    qCDebug(dcTags) << "Filtering tag. ID:" << tag->tagId() << "Thing:" << tag->thingId() << "Value:" << tag->value();
    qCDebug(dcTags) << "Filter: ID:" << m_filterTagId << "Thing:" << m_filterThingId << "value:" << m_filterValue;
    if (!m_filterTagId.isEmpty()) {
        QRegularExpression exp(m_filterTagId);
        if (exp.match(tag->tagId()).hasMatch()) {
            return false;
        }
    }
    if (!m_filterThingId.isNull()) {
        if (tag->thingId() != m_filterThingId) {
            return false;
        }
    }
    if (!m_filterRuleId.isNull()) {
        if (tag->ruleId() != m_filterRuleId) {
            return false;
        }
    }
    if (!m_filterValue.isEmpty()) {
        if (tag->value() != m_filterValue) {
            return false;
        }
    }
    qCDebug(dcTags) << "Accepted!";
    return true;
}

bool TagsProxyModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    QString leftValue = m_tags->get(source_left.row())->value();
    QString rightValue = m_tags->get(source_right.row())->value();
    bool okLeft, okRight;
    qlonglong leftAsNumber = leftValue.toLongLong(&okLeft);
    qlonglong rightAsNumber = rightValue.toLongLong(&okRight);
    if (okLeft && okRight) {
        return leftAsNumber < rightAsNumber;
    }
    return leftValue < rightValue;
}
