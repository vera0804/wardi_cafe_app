import { apiRequest } from './api.js';

/**
 * @returns {Promise<{ requiresContractAcceptance: boolean, contractVersion: string, previousContractVersion: string | null }>}
 */
export async function fetchContractStatus() {
  return apiRequest('/api/contracts/status');
}

/**
 * @param {string} version
 */
export async function acceptContract(version) {
  return apiRequest('/api/contracts/accept', {
    method: 'POST',
    body: JSON.stringify({ version }),
  });
}
