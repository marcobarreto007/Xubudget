import React from 'react';
import { motion } from 'framer-motion';
import { Receipt, Trash2, Edit3, Eye, Calendar, DollarSign } from 'lucide-react';

interface Expense {
  id: string;
  description: string;
  amount: number;
  category: string;
  date: string;
  receiptImage?: string;
  vendor?: string;
}

interface ExpenseListProps {
  expenses: Expense[];
  onReceiptClick: () => void;
}

const ExpenseList: React.FC<ExpenseListProps> = ({ expenses, onReceiptClick }) => {
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

  const getCategoryColor = (category: string) => {
    const colors = {
      food: 'from-red-500 to-pink-500',
      transport: 'from-blue-500 to-cyan-500',
      health: 'from-green-500 to-emerald-500',
      housing: 'from-purple-500 to-indigo-500',
      utilities: 'from-yellow-500 to-orange-500',
      shopping: 'from-pink-500 to-rose-500',
      entertainment: 'from-indigo-500 to-purple-500',
      education: 'from-teal-500 to-cyan-500',
      savings: 'from-emerald-500 to-green-500',
      other: 'from-gray-500 to-slate-500'
    };
    return colors[category as keyof typeof colors] || colors.other;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex items-center justify-between"
      >
        <div>
          <h2 className="text-2xl font-bold text-white">Your Expenses</h2>
          <p className="text-purple-200">Track and manage your spending</p>
        </div>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={onReceiptClick}
          className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-medium flex items-center space-x-2"
        >
          <Receipt className="w-5 h-5" />
          <span>Add Receipt</span>
        </motion.button>
      </motion.div>

      {/* Expenses List */}
      <div className="space-y-4">
        {expenses.length > 0 ? (
          expenses.map((expense, index) => (
            <motion.div
              key={expense.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="glass rounded-2xl p-6 hover:bg-white/10 transition-all duration-300"
            >
              <div className="flex items-center space-x-4">
                {/* Receipt Image or Category Icon */}
                <div className="flex-shrink-0">
                  {expense.receiptImage ? (
                    <img
                      src={expense.receiptImage}
                      alt="Receipt"
                      className="w-16 h-20 rounded-lg object-cover border-2 border-purple-400"
                    />
                  ) : (
                    <div className={`w-16 h-20 bg-gradient-to-r ${getCategoryColor(expense.category)} rounded-lg flex items-center justify-center`}>
                      <span className="text-3xl">{getCategoryIcon(expense.category)}</span>
                    </div>
                  )}
                </div>

                {/* Expense Details */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="text-white font-semibold text-lg">{expense.description}</h3>
                      <p className="text-purple-200 text-sm capitalize">{expense.category}</p>
                      {expense.vendor && (
                        <p className="text-purple-300 text-sm">{expense.vendor}</p>
                      )}
                      <div className="flex items-center space-x-4 mt-2">
                        <div className="flex items-center space-x-1 text-purple-200 text-sm">
                          <Calendar className="w-4 h-4" />
                          <span>{new Date(expense.date).toLocaleDateString()}</span>
                        </div>
                        <div className="flex items-center space-x-1 text-purple-200 text-sm">
                          <DollarSign className="w-4 h-4" />
                          <span>${expense.amount.toFixed(2)}</span>
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center space-x-2">
                      <motion.button
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        className="p-2 hover:bg-white/20 rounded-lg transition-colors"
                      >
                        <Eye className="w-4 h-4 text-white" />
                      </motion.button>
                      <motion.button
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        className="p-2 hover:bg-white/20 rounded-lg transition-colors"
                      >
                        <Edit3 className="w-4 h-4 text-white" />
                      </motion.button>
                      <motion.button
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        className="p-2 hover:bg-red-500/20 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-4 h-4 text-red-400" />
                      </motion.button>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          ))
        ) : (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center py-16"
          >
            <div className="w-32 h-32 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center mx-auto mb-6">
              <Receipt className="w-16 h-16 text-white" />
            </div>
            <h3 className="text-2xl font-bold text-white mb-4">No expenses yet</h3>
            <p className="text-purple-200 mb-8">Start by scanning your first receipt!</p>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={onReceiptClick}
              className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-8 py-4 rounded-lg font-medium text-lg"
            >
              Scan Receipt
            </motion.button>
          </motion.div>
        )}
      </div>
    </div>
  );
};

export default ExpenseList;
