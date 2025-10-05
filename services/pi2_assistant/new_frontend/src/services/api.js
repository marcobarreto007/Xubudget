import axios from 'axios';

const API_BASE_URL = 'http://127.0.0.1:5002/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});

export const expenseService = {
  // Get all expenses
  getExpenses: async (days) => {
    const response = await api.get('/expenses', {
      params: { days }
    });
    return response.data;
  },

  // Add new expense
  addExpense: async (expense) => {
    const response = await api.post('/expenses', expense);
    return response.data;
  },

  // Delete expense
  deleteExpense: async (id) => {
    await api.delete(`/expenses/${id}`);
  },

  // Get expenses by category
  getByCategory: async (category) => {
    const response = await api.get('/expenses/by-category', {
      params: { category }
    });
    return response.data;
  },

  // Get summary
  getSummary: async () => {
    const response = await api.get('/expenses/summary');
    return response.data;
  },

  // Categorize expense text
  categorize: async (text) => {
    const response = await api.post('/categorize', { text });
    return response.data;
  },

  // Health check
  health: async () => {
    const response = await api.get('/health');
    return response.data;
  },
};

export default api;
