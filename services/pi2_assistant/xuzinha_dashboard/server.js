const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Servir arquivos estáticos
app.use(express.static(path.join(__dirname, 'build')));

// Todas as rotas vão para index.html (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🚀 Xuzinha está rodando em: http://localhost:${PORT}`);
  console.log(`🌐 Acesse: http://localhost:${PORT}`);
});
