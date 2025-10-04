@echo off
setlocal enabledelayedexpansion
REM WHY: HTTPS único (front+api) com Nginx proxy, pronto p/ celular sem mixed content

REM 0) Ir para raiz do projeto (ajuste se necessário)
cd /d C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant || goto :err

REM 1) Detectar IP da LAN (pega primeira ocorrência)
set LAN_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r /c:"IPv4 Address" /c:"Endere"') do (
  set raw=%%a
  set ip1=!raw: =!
  for /f "tokens=1 delims=(" %%b in ("!ip1!") do set LAN_IP=%%b
  if "!LAN_IP!" NEQ "" goto :ip_ok
)
:ip_ok
if "%LAN_IP%"=="" (
  echo [ERRO] Nao foi possivel detectar o IP da LAN. Informe manualmente no script e reexecute.
  pause
  exit /b 1
)
echo LAN_IP = %LAN_IP%

REM 2) Pastas
if not exist nginx mkdir nginx
if not exist nginx\certs mkdir nginx\certs

REM 3) Certificados com mkcert (localhost + IP da LAN)
REM (mkcert via npx; instala CA local se faltar)
call npx mkcert -install
call npx mkcert -cert-file nginx\certs\server.crt -key-file nginx\certs\server.key localhost 127.0.0.1 ::1 %LAN_IP%

REM 4) Build do frontend (garantir assets atualizados) + precompress (.br/.gz)
cd new_frontend || goto :err
call npm run build || goto :err
REM Precompress assets for Brotli/Gzip static serving
if not exist scripts mkdir scripts
if not exist scripts\precompress.mjs (
  > scripts\precompress.mjs echo import fs from 'fs';
  >> scripts\precompress.mjs echo import path from 'path';
  >> scripts\precompress.mjs echo import { promisify } from 'util';
  >> scripts\precompress.mjs echo import zlib from 'zlib';
  >> scripts\precompress.mjs echo const exts = new Set(['.html','.js','.css','.json','.svg','.xml','.txt','.wasm']);
  >> scripts\precompress.mjs echo const brotli = promisify(zlib.brotliCompress);
  >> scripts\precompress.mjs echo const gzip = promisify(zlib.gzip);
  >> scripts\precompress.mjs echo async function walk(dir){ const out=[]; for(const f of await fs.promises.readdir(dir)){ const p=path.join(dir,f); const st=await fs.promises.stat(p); if(st.isDirectory()) out.push(...await walk(p)); else out.push(p);} return out; }
  >> scripts\precompress.mjs echo async function run(root){ const files=await walk(root); for(const f of files){ const ext=path.extname(f).toLowerCase(); if(!exts.has(ext)) continue; const data=await fs.promises.readFile(f); try{ const br=await brotli(data,{params:{[zlib.constants.BROTLI_PARAM_QUALITY]:11}}); await fs.promises.writeFile(f+'.br', br);}catch(e){ console.error('brotli fail',f,e.message);} try{ const gz=await gzip(data,{level:9}); await fs.promises.writeFile(f+'.gz', gz);}catch(e){ console.error('gzip fail',f,e.message);} } }
  >> scripts\precompress.mjs echo const target = process.argv[2]||'build'; run(path.resolve(process.cwd(), target)).catch(e=>{ console.error(e); process.exit(1); });
)
node scripts\precompress.mjs build || echo [WARN] precompress falhou; seguindo sem .br/.gz
cd ..

REM 5) Subir API + WEB com compose combinado
docker compose -f docker-compose.yml -f docker-compose.https.yml down --remove-orphans
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d --build api
docker compose -f docker-compose.yml -f docker-compose.https.yml build web
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d web

REM Abrir firewall UDP 443 para QUIC/HTTP3
netsh advfirewall firewall add rule name="Xuzinha QUIC 443 UDP" dir=in action=allow protocol=UDP localport=443 >nul 2>&1
REM Abrir firewall TCP 443 para HTTPS
netsh advfirewall firewall add rule name="Xuzinha HTTPS 443 TCP" dir=in action=allow protocol=TCP localport=443 >nul 2>&1

REM 6) Abrir no desktop e mostrar URL do celular
start https://localhost/#/dashboard
echo.
echo ==================================================================
echo  Abra no CELULAR (mesma rede):
echo      https://%LAN_IP%/#/dashboard
echo  Aceite o certificado local quando solicitado.
echo ==================================================================
echo.
docker compose -f docker-compose.yml -f docker-compose.https.yml ps
echo.
pause
goto :eof

:err
echo [ERRO] Falha ao executar.
pause
