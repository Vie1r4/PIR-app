/**
 * PIR - Perigo de Incêndio Rural (IPMA)
 * Endpoint Serverless v1 da Vercel para servir a previsão alargada de 9 dias
 * 
 * Rota: /api/v1/rcm-9dias
 * Fonte oficial: Instituto Português do Mar e da Atmosfera (IPMA)
 */

const IPMA_URL_PRIMARY = 'https://www.ipma.pt/pt/riscoincendio/rcm.pt/index.jsp';
const IPMA_URL_FALLBACK = 'https://www.ipma.pt/pt/ambiente/risco.incendio/';
const USER_AGENT = 'PIR-App/1.2.0 (+https://github.com/Vie1r4/PIR-app; shovieira@gmail.com)';

// Cache em memória a nível de módulo (global scope fora do handler) para instâncias warm
let lastValidPayload = null;
let lastValidTimestamp = 0;
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hora

async function fetchHtmlWithTimeout(url, timeoutMs = 6000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': USER_AGENT,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'pt-PT,pt;q=0.9,en;q=0.8',
      },
    });

    if (!res.ok) {
      throw new Error(`HTTP ${res.status} de ${url}`);
    }

    return await res.text();
  } finally {
    clearTimeout(timer);
  }
}

function parseIpmaHtml(html) {
  const regex = /rcmF\[(\d+)\]\s*=\s*(\{.*?\});/gs;
  const matches = [];
  let match;

  while ((match = regex.exec(html)) !== null) {
    matches.push({
      index: parseInt(match[1], 10),
      jsonStr: match[2],
    });
  }

  matches.sort((a, b) => a.index - b.index);

  const results = [];
  for (const item of matches) {
    try {
      const parsed = JSON.parse(item.jsonStr);
      results.push(parsed);
    } catch {
      // Ignora blocos com parse corrompido
    }
  }

  return results;
}

export default async function handler(req, res) {
  // Configuração universal de CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Preflight CORS
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ erro: 'Método não permitido. Utilize GET.' });
  }

  const now = Date.now();

  // 1. Verifica cache em memória a nível de módulo (se ainda for válida dentro do TTL)
  if (lastValidPayload && (now - lastValidTimestamp < CACHE_TTL_MS)) {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
    res.setHeader('X-Cache', 'HIT');
    return res.status(200).json(lastValidPayload);
  }

  // 2. Tenta extrair dados frescos do IPMA com timeout estrito de 6 segundos
  let html = null;
  try {
    html = await fetchHtmlWithTimeout(IPMA_URL_PRIMARY, 6000);
  } catch (errPrimary) {
    console.warn(`[IPMA API v1] Falha no endpoint primário: ${errPrimary.message}. A tentar fallback...`);
    try {
      html = await fetchHtmlWithTimeout(IPMA_URL_FALLBACK, 6000);
    } catch (errFallback) {
      console.error(`[IPMA API v1] Ambos os endpoints falharam: ${errFallback.message}`);
    }
  }

  if (html) {
    const dados = parseIpmaHtml(html);
    if (dados.length > 0) {
      lastValidPayload = dados;
      lastValidTimestamp = now;

      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
      res.setHeader('X-Cache', 'MISS');
      return res.status(200).json(dados);
    }
  }

  // 3. Degradação Graciosa: Se a chamada síncrona ao IPMA falhou ou deu timeout,
  // reutiliza a última resposta válida da instância warm (mesmo com TTL ultrapassado)
  if (lastValidPayload) {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=300, stale-while-revalidate=600');
    res.setHeader('X-Cache', 'STALE');
    return res.status(200).json(lastValidPayload);
  }

  // 4. Contingência final se não houver dados de todo
  return res.status(503).json({
    status: 'error',
    message: 'Serviço oficial do IPMA temporariamente inacessível.',
    timestamp: new Date().toISOString(),
  });
}
