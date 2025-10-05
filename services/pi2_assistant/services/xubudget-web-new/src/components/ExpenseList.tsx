import React from 'react';
import { Trash2, Edit } from 'lucide-react';
import { Expense, CATEGORY_LABELS, CATEGORY_COLORS } from '../types';
import { formatCurrency } from '../utils/format';

interface ExpenseListProps {
  expenses: Expense[];
  onDelete: (id: number) => void;
  loading?: boolean;
}

const ExpenseList: React.FC<ExpenseListProps> = ({ expenses, onDelete, loading }) => {
  if (loading) {
    return (
      <div className="flex justify-center items-center h-32">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (expenses.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        <p>No expenses found. Add your first expense!</p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {expenses.map((expense) => (
        <div
          key={expense.id}
          className="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <div className="flex items-center space-x-3">
                <div
                  className="w-3 h-3 rounded-full"
                  style={{ backgroundColor: CATEGORY_COLORS[expense.category] }}
                />
                <div>
                  <h3 className="font-medium text-gray-900">{expense.description}</h3>
                  <p className="text-sm text-gray-500">
                    {CATEGORY_LABELS[expense.category]} • {expense.date}
                  </p>
                </div>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <span className="font-semibold text-gray-900">
                {formatCurrency(expense.amount)}
              </span>
              <button
                onClick={() => onDelete(expense.id)}
                className="p-1 text-red-500 hover:text-red-700 hover:bg-red-50 rounded"
                title="Delete expense"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default ExpenseList;
