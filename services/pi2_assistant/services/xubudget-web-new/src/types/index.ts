export interface Expense {
  id: number;
  description: string;
  amount: number;
  category: string;
  date: string;
  created_at: string;
}

export interface ExpenseInput {
  description: string;
  amount: number;
  category: string;
  date?: string;
}

export interface Summary {
  categories: CategorySummary[];
  total_amount: number;
  total_count: number;
  recent_expense: {
    description: string;
    amount: number;
    date: string;
  } | null;
}

export interface CategorySummary {
  category: string;
  count: number;
  total: number;
  average: number;
}

export interface CategorizeResponse {
  category: string;
  confidence: number;
}

export type CategoryType = 'food' | 'transport' | 'health' | 'housing' | 'utilities' | 'shopping' | 'entertainment' | 'education' | 'savings' | 'other';

export const CATEGORY_COLORS: Record<string, string> = {
  food: '#10b981',        // Green
  transport: '#3b82f6',   // Blue
  health: '#ef4444',      // Red
  housing: '#8b5cf6',     // Purple
  utilities: '#84cc16',   // Lime
  shopping: '#ec4899',    // Pink
  entertainment: '#f97316', // Orange
  education: '#06b6d4',   // Cyan
  savings: '#fbbf24',     // Yellow
  other: '#6b7280',       // Gray
};

export const CATEGORY_ICONS: Record<string, string> = {
  food: '🍽️',
  transport: '🚗',
  health: '💊',
  housing: '🏠',
  utilities: '⚡',
  shopping: '🛍️',
  entertainment: '🎬',
  education: '📚',
  savings: '💰',
  other: '📦',
};

export const CATEGORY_LABELS: Record<string, string> = {
  food: 'Food & Groceries',
  transport: 'Transportation',
  health: 'Health & Medical',
  housing: 'Housing & Rent',
  utilities: 'Utilities & Bills',
  shopping: 'Shopping & Personal',
  entertainment: 'Entertainment & Fun',
  education: 'Education & Learning',
  savings: 'Savings & Investment',
  other: 'Other Expenses',
};
