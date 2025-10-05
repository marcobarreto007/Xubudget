// Backend Sync Service - Sincroniza chat com dados reais do backend
const API_BASE_URL = 'http://127.0.0.1:8000/api';

export interface BackendState {
  user_id: string;
  budget: number;
  monthly_spent: number;
  remaining: number;
  history: Array<{
    type: 'expense' | 'income';
    amount: number;
    description: string;
    category: string;
    timestamp: string;
    id?: string;
  }>;
  category_budgets: { [key: string]: number };
  incomes: Array<{
    amount: number;
    source: string;
    timestamp: string;
  }>;
  settings: any;
  icons: Array<{
    id: string;
    name: string;
    emoji: string;
    budget: number;
    spent: number;
    active: boolean;
  }>;
}

export interface ChatResponse {
  final_answer: string;
  used_tools: string[];
  response?: string;
  spoken?: string;
  state?: BackendState;
  intent_handled?: boolean;
  duplicate?: boolean;
}

class BackendSyncService {
  private baseUrl: string;

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async sendMessage(message: string, userId: string = 'default'): Promise<ChatResponse> {
    try {
      const response = await fetch(`${this.baseUrl}/chat/xuzinha`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_id: userId,
          message: message
        })
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Backend sync error:', error);
      throw error;
    }
  }

  async getCurrentState(userId: string = 'default'): Promise<BackendState> {
    try {
      const response = await fetch(`${this.baseUrl}/state?user_id=${userId}`);
      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }
      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Failed to get current state:', error);
      throw error;
    }
  }

  // Refresh budget totals after modifications
  async refreshBudgetTotals() {
    try {
      const response = await fetch(`${this.baseUrl}/expenses/totals`);
      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }
      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Failed to refresh budget totals:', error);
      throw error;
    }
  }

  // Converte dados do backend para formato do frontend
  convertBackendToFrontend(backendState: BackendState) {
    const expenses = backendState.history
      .filter(item => item.type === 'expense')
      .map(item => ({
        id: item.id || Date.now().toString(),
        amount: item.amount,
        category: item.category,
        description: item.description,
        date: new Date(item.timestamp).toISOString().split('T')[0],
        receiptImage: undefined,
        vendor: undefined
      }));

    const incomes = backendState.incomes.map(income => ({
      id: Date.now().toString(),
      amount: income.amount,
      source: income.source,
      date: new Date(income.timestamp).toISOString().split('T')[0]
    }));

    return {
      expenses,
      incomes,
      totalBudget: backendState.budget,
      totalSpent: backendState.monthly_spent,
      remaining: backendState.remaining,
      categoryBudgets: backendState.category_budgets,
      icons: backendState.icons
    };
  }

  // Calcula totais atualizados
  calculateTotals(backendState: BackendState) {
    const totalIncomes = backendState.incomes.reduce((sum, income) => sum + income.amount, 0);
    const totalExpenses = backendState.history
      .filter(item => item.type === 'expense')
      .reduce((sum, expense) => sum + expense.amount, 0);
    
    return {
      totalIncomes,
      totalExpenses,
      remaining: backendState.remaining,
      budget: backendState.budget
    };
  }
}

export const backendSyncService = new BackendSyncService();
