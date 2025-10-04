const fs = require('fs');
const path = require('path');
const exts = new Set(['.js','.jsx','.ts','.tsx','.css','.html']);
function walk(dir){ 
  for(const f of fs.readdirSync(dir)){ 
    const p=path.join(dir,f); 
    const s=fs.statSync(p); 
    if(s.isDirectory()) walk(p); 
    else if(exts.has(path.extname(p))){
      const buf=fs.readFileSync(p); 
      if(buf[0]===0xEF && buf[1]===0xBB && buf[2]===0xBF){
        fs.writeFileSync(p, buf.slice(3)); 
        console.log('stripped', p);
      }
    }
  }
}
walk(path.join(__dirname,'new_frontend','src'));
