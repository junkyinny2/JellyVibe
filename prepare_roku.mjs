import fs from 'fs';
import path from 'path';
import { glob } from 'fs/promises';

// 1. Copy all .bs files as .brs
const bsFiles = [];
function walkDir(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            walkDir(full);
        } else if (entry.name.endsWith('.bs')) {
            bsFiles.push(full);
        }
    }
}

const roots = ['source', 'components'];
for (const r of roots) walkDir(r);

console.log(`Found ${bsFiles.length} .bs files, copying as .brs...`);
for (const f of bsFiles) {
    const dest = f.slice(0, -3) + '.brs';
    fs.copyFileSync(f, dest);
}

// 2. For each .xml in components, inject a <script> tag if the sibling .brs exists and no script tag present
function walkXml(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            walkXml(full);
        } else if (entry.name.endsWith('.xml')) {
            const brsName = entry.name.replace('.xml', '.brs');
            const brsPath = path.join(dir, brsName);
            if (!fs.existsSync(brsPath)) continue;

            let xml = fs.readFileSync(full, 'utf8');
            // Skip if already has a uri=".brs" script reference
            if (xml.includes('.brs"') || xml.includes(".brs'")) continue;

            // relative pkg path
            const rel = full.replace(/\\/g, '/').replace('components/', '');
            const dirPart = path.dirname(rel).replace('components/', '');
            const pkgPath = `pkg:/components/${rel.replace(/^components\//, '').replace(entry.name, brsName)}`;

            const scriptTag = `\n  <script type="text/brightscript" uri="${pkgPath}" />`;

            // Insert before </component>
            if (xml.includes('</component>')) {
                xml = xml.replace('</component>', scriptTag + '\n</component>');
                fs.writeFileSync(full, xml, 'utf8');
                console.log(`  Patched: ${full}`);
            }
        }
    }
}

console.log('Patching XML files with script tags...');
walkXml('components');

console.log('Done! Now run the zip command.');
