with open(r'components\movies\MovieDetails.xml', 'rb') as f:
    data = f.read()

text = data.decode('utf-8')

old_block = (
    '        <!-- Audio column (static text with box) -->\r\n'
    '      <LayoutGroup layoutDirection="vert" itemSpacings="[4]">\r\n'
    '        <Text text="Audio" font="font:SmallestBoldSystemFont" color="#bbbbbb" />\r\n'
    '        <Group>\r\n'
    '          <Rectangle id="audioBg" width="280" height="48" color="#55020B2A" />\r\n'
    '          <Text id="audioText" font="font:SmallSystemFont" color="#e8e8ee" width="280" height="48" horizAlign="left" vertAlign="top" />\r\n'
    '        </Group>\r\n'
    '      </LayoutGroup>'
)

new_block = (
    '        <!-- Audio column (dropdown button) -->\r\n'
    '      <LayoutGroup layoutDirection="vert" itemSpacings="[4]">\r\n'
    '        <Text text="Audio" font="font:SmallestBoldSystemFont" color="#bbbbbb" />\r\n'
    '        <TextButton id="audioButton" iconSide="right" fontSize="22" padding="15"\r\n'
    '          icon="pkg:/images/icons/dropdown-dark.png" focusIcon="pkg:/images/icons/dropdown-light.png"\r\n'
    '          text="" height="48" width="280"\r\n'
    '          background="#55020B2A" focusBackground="#FFFFFF"\r\n'
    '          textColor="#FFFFFF" focusTextColor="#000000" focusable="true" />\r\n'
    '      </LayoutGroup>'
)

if old_block in text:
    text = text.replace(old_block, new_block)
    with open(r'components\movies\MovieDetails.xml', 'wb') as f:
        f.write(text.encode('utf-8'))
    print('SUCCESS: Audio column replaced')
else:
    print('FAIL: Pattern not found')
    # Debug: show the relevant section
    idx = text.find('Audio column')
    if idx >= 0:
        print(repr(text[idx:idx+500]))
