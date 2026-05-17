with open(r'components\movies\MovieDetails.xml', 'rb') as f:
    data = f.read()

text = data.decode('utf-8')

old_block = (
    '        <!-- Video column (inline expanded list) -->\r\n'
    '      <LayoutGroup layoutDirection="vert" itemSpacings="[4]">\r\n'
    '        <Text id="videoLabel" text="Version" font="font:SmallestBoldSystemFont" color="#bbbbbb" />\r\n'
    '        <VersionSelector id="videoSelector" itemWidth="320" />\r\n'
    '      </LayoutGroup>'
)

new_block = (
    '        <!-- Video column (dropdown button) -->\r\n'
    '      <LayoutGroup layoutDirection="vert" itemSpacings="[4]">\r\n'
    '        <Text text="Video" font="font:SmallestBoldSystemFont" color="#bbbbbb" />\r\n'
    '        <TextButton id="videoButton" iconSide="right" fontSize="22" padding="15"\r\n'
    '          icon="pkg:/images/icons/dropdown-dark.png" focusIcon="pkg:/images/icons/dropdown-light.png"\r\n'
    '          text="" height="48" width="320"\r\n'
    '          background="#55020B2A" focusBackground="ColorPalette.WHITE"\r\n'
    '          textColor="#FFFFFF" focusTextColor="#000000" focusable="true" />\r\n'
    '      </LayoutGroup>'
)

if old_block in text:
    text = text.replace(old_block, new_block)
    with open(r'components\movies\MovieDetails.xml', 'wb') as f:
        f.write(text.encode('utf-8'))
    print('SUCCESS: Video column replaced')
else:
    print('FAIL: Pattern not found')
    idx = text.find('Video column')
    if idx >= 0:
        print(repr(text[idx:idx+300]))
