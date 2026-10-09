/**
 * PIR - Perigo de Incêndio Rural
 * Alias de retrocompatibilidade: reencaminha para /api/v1/rcm-9dias
 */
import v1Handler from './v1/rcm-9dias.js';

export default function handler(req, res) {
  return v1Handler(req, res);
}
