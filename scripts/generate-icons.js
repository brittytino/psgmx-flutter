const sharp = require('sharp');
const fs = require('fs');

const sizes = [192, 512];
const inputSvg = `
<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
  <rect width="512" height="512" fill="#3B82F6"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" 
        font-size="200" fill="white" font-family="Arial, sans-serif" font-weight="bold">
    PP
  </text>
</svg>
`;

async function generateIcons() {
  for (const size of sizes) {
    await sharp(Buffer.from(inputSvg))
      .resize(size, size)
      .png()
      .toFile(`public/icon-${size}.png`);
    console.log(`Generated icon-${size}.png`);
  }
}

generateIcons().catch(console.error);
