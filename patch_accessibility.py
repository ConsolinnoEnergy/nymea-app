# Note: This should be done using a proper QML parser. However I couldn't find
# an easy to use one. Thus this scripts uses regex substitution which can
# easily go wrong. Be warned!
import argparse
import re
from string import Template

button_match_num = 0
checkbox_match_num = 0
textfield_match_num = 0

combobox_delegate_template = Template(
    """delegate: ItemDelegate {
              width: $elemid.width
              contentItem: Text {
                  text: $elemid.textRole
                        ? (Array.isArray($elemid.model) ? modelData[$elemid.textRole] : model[$elemid.textRole])
                        : modelData
                  font: $elemid.font
                  elide: Text.ElideRight
                  Accessible.name: $elemid.textRole
                                   ? (Array.isArray($elemid.model) ? modelData[$elemid.textRole] : model[$elemid.textRole])
                                   : modelData
              }
              highlighted: $elemid.highlightedIndex === index
}
"""
)


def parse_element_id(el):
    try:
        el_id = re.findall("id:(.*)", el)
        el_id = el_id[0].strip()
        if " " in el_id or '"' in el_id:
            print("Warning: Unvailid id parsed")
            raise Exception("Parsed id invalid")
    except Exception as e:
        print("Info: No QML id defined for element")
        el_id = None
    return el_id


def patch_combox(match):
    # This sucks, but match does not bring the match number
    # Would need to refactor the script to get the number in a nicer way
    global checkbox_match_num
    checkbox_match_num += 1

    el = match.group()
    qml_id = el_id = parse_element_id(el)
    set_id = False
    if not el_id:
        set_id = True
        el_id = f"ComboBox_{checkbox_match_num}"
        qml_id = el_id.lower().replace("_", "")

    lines = el.splitlines()
    if lines[0].lstrip().startswith("//"):
        print("Info: Skipping commented element.")
        return el
    # Let's clean empty lines
    try:
        lines.remove("")
    except ValueError:
        pass
    indent = lines[1].count(" ")  # Identation of last attribute line
    if set_id:
        lines.insert(1, (indent - 1) * " " + f"id: {qml_id}")
    lines.insert(1, (indent - 1) * " " + f'Accessible.name: "{el_id}"')
    lines.insert(1, (indent - 1) * " " + f"Accessible.role: Accessible.ComboBox")
    if el.find("delegate:") == -1:  # Has delegate already
        # Skips for example ui/delegate/ParamDelegate.qml:271
        delegate = combobox_delegate_template.substitute(elemid=qml_id)
        # Add in reversed order, because we insert on top of list
        for dline in reversed(delegate.splitlines()):
            lines.insert(1, (indent - 1) * " " + dline)
    return "\n".join(lines)


def patch_checkbox(match):
    # This sucks, but match does not bring the match number
    # Would need to refactor the script to get the number in a nicer way
    global checkbox_match_num
    checkbox_match_num += 1

    el = match.group()
    el_id = parse_element_id(el)
    if not el_id:
        el_id = f"Checkbox_{checkbox_match_num}"

    lines = el.splitlines()
    if lines[0].lstrip().startswith("//"):
        print("Info: Skipping commented element.")
        return el
    # Let's clean empty lines
    try:
        lines.remove("")
    except ValueError:
        pass
    indent = lines[1].count(" ")  # Identation of last attribute line
    lines.insert(1, (indent - 1) * " " + f'Accessible.name: "{el_id}"')
    lines.insert(1, (indent - 1) * " " + f"Accessible.role: Accessible.CheckBox")
    lines.insert(1, (indent - 1) * " " + "Accessible.checkable: true")
    return "\n".join(lines)


def patch_button(match):
    # This sucks, but match does not bring the match number
    # Would need to refactor the script to get the number in a nicer way
    global button_match_num
    button_match_num += 1
    el = match.group()
    el_id = parse_element_id(el)
    if not el_id:
        el_id = f"Button_{button_match_num}"

    lines = el.splitlines()
    if lines[0].lstrip().startswith("//"):
        print("Info: Skipping commented element.")
        return el
    # Let's clean empty lines
    try:
        lines.remove("")
    except ValueError:
        pass
    indent = lines[1].count(" ")  # Identation of last attribute line
    lines.insert(1, (indent - 1) * " " + f'Accessible.name: "{el_id}"')
    lines.insert(1, (indent - 1) * " " + f"Accessible.role: Accessible.Button")

    return "\n".join(lines)


def patch_textfield(match):
    # This sucks, but match does not bring the match number
    # Would need to refactor the script to get the number in a nicer way
    global textfield_match_num
    textfield_match_num += 1

    el = match.group()
    el_id = parse_element_id(el)
    if not el_id:
        el_id = f"TextField_{textfield_match_num}"

    lines = el.splitlines()
    if lines[0].lstrip().startswith("//"):
        print("Info: Skipping commented element.")
        return el
    # Let's clean empty lines
    try:
        lines.remove("")
    except ValueError:
        pass
    indent = lines[1].count(" ")  # Identation of last attribute line
    lines.insert(1, (indent - 1) * " " + f'Accessible.name: "{el_id}"')
    lines.insert(1, (indent - 1) * " " + f"Accessible.editable: true")
    lines.insert(1, (indent - 1) * " " + f"Accessible.role: Accessible.EditableText")

    return "\n".join(lines)


def patch_file(filename, inplace=False):
    # This sucks, but would need to use smth other than re.sub function
    # to get rid of these global vars
    global button_match_num
    global checkbox_match_num
    global textfield_match_num
    button_match_num = 0
    checkbox_match_num = 0
    textfield_match_num = 0

    with open(filename) as f:
        qml = f.read()

    # Matches CheckBox{ .... } including line breaks
    res = re.sub("^.*CheckBox\s?{(?s:.*?)}", patch_checkbox, qml, flags=re.M)
    # Matches Button{ .... } including line breaks
    res = re.sub("^.*Button\s?{(?s:.*?)}", patch_button, res, flags=re.M)
    # Matches TextField{ .... } including line breaks
    res = re.sub("^.*TextField\s?{(?s:.*?)}", patch_textfield, res, flags=re.M)
    # Matches ComboBox{ .... } including line breaks
    res = re.sub("^.*ComboBox\s?{(?s:.*?)}", patch_combox, res, flags=re.M)

    outfile = filename if inplace == True else filename + ".patched"
    with open(outfile, "w") as f:
        f.write(res)


def main():
    p = argparse.ArgumentParser()
    p.add_argument(
        "filename",
        help="Path of QML file to be patched",
    )
    p.add_argument(
        "--inplace",
        help="Patch inplace and alter original file",
        action="store_true",
        default=False,
    )
    args = p.parse_args()
    patch_file(args.filename, inplace=args.inplace)


if __name__ == "__main__":
    main()
