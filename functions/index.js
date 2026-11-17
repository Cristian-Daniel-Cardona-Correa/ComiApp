const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function para la creación segura de Tokens Efímeros de Gemini Live.
 * 
 * Regla de Seguridad Obligatoria:
 * La API key de Gemini NUNCA va dentro de la aplicación cliente.
 * El cliente móvil se autentica con su Firebase ID Token, y esta función
 * solicita un token efímero a Google Gemini (con uses: 1 y expiración de 60 segundos).
 */
exports.getGeminiEphemeralToken = onRequest(
  {
    cors: true,
    region: "us-central1",
    secrets: ["GEMINI_API_KEY"],
  },
  async (req, res) => {
    // 1. Validar método HTTP
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Método no permitido. Usa POST." });
    }

    // 2. Validar autenticación de Firebase Auth
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        error: "No autorizado. Se requiere token Bearer de Firebase Auth.",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (authError) {
      return res.status(401).json({
        error: "Token de Firebase Auth inválido o expirado.",
        details: authError.message,
      });
    }

    // 3. Obtener la API Key protegida desde Google Cloud Secret Manager
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({
        error: "La clave GEMINI_API_KEY no está configurada en Cloud Secret Manager.",
      });
    }

    // 4. Solicitar token efímero a la API v1beta de Gemini Live
    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/ephemeralTokens?key=${apiKey}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            // Especificaciones requeridas: un solo uso y expiración corta
            uses: 1,
            newSessionExpireTime: "60s",
            clientMetadata: {
              userId: decodedToken.uid,
              app: "comiAPP",
            },
          }),
        }
      );

      if (!response.ok) {
        const errorBody = await response.text();
        return res.status(response.status).json({
          error: "Error emitido por Google Gemini al solicitar token efímero.",
          details: errorBody,
        });
      }

      const data = await response.json();
      return res.status(200).json({
        token: data.name || data.token,
        expireTime: data.expireTime,
      });
    } catch (networkError) {
      return res.status(502).json({
        error: "Error de red al conectar con Google Gemini API.",
        details: networkError.message,
      });
    }
  }
);
