import React from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, TrendingDown, Wallet, Heart, Receipt } from 'lucide-react';

interface Expense {
  id: string;
  description: string;
  amount: number;
  category: string;
  date: string;
  receiptImage?: string;
  vendor?: string;
}

interface CategoryRemaining {
  category: string;
  budget: number;
  spent: number;
  remaining: number;
  percentage: number;
}

interface BudgetOverviewProps {
  expenses: Expense[];
  monthlyIncome: number;
  weeklyIncome: number;
  governmentAssistance: number;
  totalWeeklyIncome: number;
  budgets: Record<string, number>;
  categoryRemaining: CategoryRemaining[];
  totalSpent: number;
  remainingBudget: number;
}

const BudgetOverview: React.FC<BudgetOverviewProps> = ({ 
  expenses, 
  monthlyIncome, 
  weeklyIncome,
  governmentAssistance,
  totalWeeklyIncome,
  budgets, 
  categoryRemaining, 
  totalSpent, 
  remainingBudget 
}) => {
  const percentageUsed = (totalSpent / monthlyIncome) * 100;

  // Removed unused topCategories - now using categoryRemaining prop

  const recentExpenses = expenses.slice(0, 5);

  // Removed unused getCategoryColor function

  const getCategoryIcon = (category: string) => {
    const icons = {
      food: '🍕',
      transport: '🚗',
      health: '🏥',
      housing: '🏠',
      utilities: '⚡',
      shopping: '🛍️',
      entertainment: '🎬',
      education: '📚',
      savings: '💰',
      other: '📦'
    };
    return icons[category as keyof typeof icons] || icons.other;
  };

  return (
    <div className="space-y-6">
      {/* Welcome Message */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="glass-purple rounded-2xl p-6"
      >
        <div className="flex items-center space-x-4">
          <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center">
            <Heart className="w-8 h-8 text-white" />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-white">Welcome back! 💜</h2>
            <p className="text-purple-200">Here's your financial overview for this month</p>
          </div>
        </div>
      </motion.div>

      {/* Budget Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Total Budget */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="glass rounded-2xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-lg flex items-center justify-center">
              <Wallet className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl">💰</span>
          </div>
          <h3 className="text-white font-semibold mb-2">Weekly Income</h3>
          <p className="text-3xl font-bold text-white">${totalWeeklyIncome.toLocaleString()}</p>
          <p className="text-blue-200 text-sm mt-1">
            ${weeklyIncome.toLocaleString()} salary + ${governmentAssistance} government
          </p>
          <p className="text-blue-300 text-xs mt-1">
            Monthly: ${monthlyIncome.toLocaleString()}
          </p>
        </motion.div>

        {/* Amount Spent */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="glass rounded-2xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-r from-red-500 to-pink-500 rounded-lg flex items-center justify-center">
              <TrendingDown className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl">💸</span>
          </div>
          <h3 className="text-white font-semibold mb-2">Amount Spent</h3>
          <p className="text-3xl font-bold text-white">${totalSpent.toLocaleString()}</p>
          <p className="text-red-200 text-sm mt-1">{percentageUsed.toFixed(1)}% of budget</p>
        </motion.div>

        {/* Remaining */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="glass rounded-2xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-emerald-500 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl">💚</span>
          </div>
          <h3 className="text-white font-semibold mb-2">Remaining</h3>
          <p className="text-3xl font-bold text-white">${remainingBudget.toLocaleString()}</p>
          <p className="text-green-200 text-sm mt-1">
            {remainingBudget > 0 ? 'Available to spend' : 'Over budget'}
          </p>
        </motion.div>
      </div>

      {/* Progress Bar */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="glass rounded-2xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-white font-semibold">Budget Progress</h3>
          <span className="text-purple-200 text-sm">{percentageUsed.toFixed(1)}% used</span>
        </div>
        <div className="w-full bg-purple-900/30 rounded-full h-4 mb-2">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${Math.min(percentageUsed, 100)}%` }}
            transition={{ duration: 1, delay: 0.5 }}
            className={`h-4 rounded-full ${
              percentageUsed > 80 
                ? 'bg-gradient-to-r from-red-500 to-pink-500' 
                : percentageUsed > 60 
                ? 'bg-gradient-to-r from-yellow-500 to-orange-500'
                : 'bg-gradient-to-r from-green-500 to-emerald-500'
            }`}
          />
        </div>
        <div className="flex justify-between text-sm text-purple-200">
          <span>$0</span>
          <span>${monthlyIncome.toLocaleString()}</span>
        </div>
      </motion.div>

      {/* Top Categories */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="glass rounded-2xl p-6"
        >
          <h3 className="text-white font-semibold mb-4">Budget by Category</h3>
          <div className="space-y-3">
            {categoryRemaining.slice(0, 5).map((category, index) => (
              <div key={category.category} className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <span className="text-2xl">{getCategoryIcon(category.category)}</span>
                    <span className="text-white capitalize">{category.category}</span>
                  </div>
                  <div className="text-right">
                    <div className="text-white font-semibold">
                      ${category.spent.toFixed(2)} / ${category.budget.toFixed(2)}
                    </div>
                    <div className={`text-xs ${category.remaining >= 0 ? 'text-green-300' : 'text-red-300'}`}>
                      {category.remaining >= 0 ? `$${category.remaining.toFixed(2)} left` : `$${Math.abs(category.remaining).toFixed(2)} over`}
                    </div>
                  </div>
                </div>
                <div className="w-full bg-gray-600 rounded-full h-2">
                  <div 
                    className={`h-2 rounded-full ${
                      category.percentage > 100 
                        ? 'bg-gradient-to-r from-red-500 to-pink-500'
                        : category.percentage > 80
                        ? 'bg-gradient-to-r from-yellow-500 to-orange-500'
                        : 'bg-gradient-to-r from-green-500 to-emerald-500'
                    }`}
                    style={{ width: `${Math.min(category.percentage, 100)}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Recent Expenses */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="glass rounded-2xl p-6"
        >
          <h3 className="text-white font-semibold mb-4">Recent Expenses</h3>
          <div className="space-y-3">
            {recentExpenses.length > 0 ? (
              recentExpenses.map((expense) => (
                <div key={expense.id} className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    {expense.receiptImage ? (
                      <img
                        src={expense.receiptImage}
                        alt="Receipt"
                        className="w-8 h-8 rounded object-cover"
                      />
                    ) : (
                      <span className="text-2xl">{getCategoryIcon(expense.category)}</span>
                    )}
                    <div>
                      <p className="text-white text-sm">{expense.description}</p>
                      <p className="text-purple-200 text-xs">{expense.date}</p>
                    </div>
                  </div>
                  <p className="text-white font-semibold">${expense.amount.toFixed(2)}</p>
                </div>
              ))
            ) : (
              <div className="text-center py-8">
                <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Receipt className="w-8 h-8 text-white" />
                </div>
                <p className="text-purple-200">No expenses yet</p>
                <p className="text-purple-300 text-sm">Start by scanning a receipt!</p>
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default BudgetOverview;
