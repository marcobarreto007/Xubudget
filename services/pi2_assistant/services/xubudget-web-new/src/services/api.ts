import axios from 'axios';
import type { Expense, ExpenseInput, Summary, CategorizeResponse } from '../types';

const API_BASE_URL = 'http://localhost:5003/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});

export const expenseService = {
  // Get all expenses
  getExpenses: async (days?: number): Promise<Expense[]> => {
    const response = await api.get('/expenses', {
      params: { days }
    });
    return response.data;
  },

  // Add new expense
  addExpense: async (expense: ExpenseInput): Promise<Expense> => {
    const response = await api.post('/expenses', expense);
    return response.data;
  },

  // Delete expense
  deleteExpense: async (id: number): Promise<void> => {
    await api.delete(`/expenses/${id}`);
  },

  // Get expenses by category
  getByCategory: async (category?: string): Promise<Expense[]> => {
    const response = await api.get('/expenses/by-category', {
      params: { category }
    });
    return response.data;
  },

  // Get summary
  getSummary: async (): Promise<Summary> => {
    const response = await api.get('/expenses/summary');
    return response.data;
  },

  // Categorize expense text
  categorize: async (text: string): Promise<CategorizeResponse> => {
    const response = await api.post('/categorize', { text });
    return response.data;
  },

  // Health check
  health: async (): Promise<{ status: string; service: string; version: string }> => {
    const response = await api.get('/health');
    return response.data;
  },
};

export default api;
