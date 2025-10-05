import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Save, Bot } from 'lucide-react';

interface Expense {
  id: string;
  description: string;
  amount: number;
  category: string;
  date: string;
  receiptImage?: string;
  vendor?: string;
}

interface ExpenseFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (expense: Omit<Expense, 'id'>) => void;
  editingExpense?: Expense | null;
  budgets: Record<string, number>;
}

const ExpenseForm: React.FC<ExpenseFormProps> = ({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingExpense,
  budgets 
}) => {
  const [formData, setFormData] = useState({
    description: '',
    amount: '',
    category: '',
    date: new Date().toISOString().split('T')[0],
    vendor: ''
  });

  const [isCategorizing, setIsCategorizing] = useState(false);

  useEffect(() => {
    console.log('ExpenseForm useEffect - editingExpense:', editingExpense);
    console.log('ExpenseForm useEffect - isOpen:', isOpen);
    
    if (editingExpense) {
      console.log('Setting form data for editing:', editingExpense);
      setFormData({
        description: editingExpense.description,
        amount: editingExpense.amount.toString(),
        category: editingExpense.category,
        date: editingExpense.date,
        vendor: editingExpense.vendor || ''
      });
    } else {
      console.log('Resetting form data for new expense');
      setFormData({
        description: '',
        amount: '',
        category: '',
        date: new Date().toISOString().split('T')[0],
        vendor: ''
      });
    }
  }, [editingExpense, isOpen]);

  const categories = Object.keys(budgets);

  const handleCategorize = async () => {
    if (!formData.description) return;
    
    setIsCategorizing(true);
    try {
      // Simulate AI categorization
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Simple keyword-based categorization
      const description = formData.description.toLowerCase();
      let suggestedCategory = 'other';
      
      if (description.includes('food') || description.includes('restaurant') || description.includes('grocery') || description.includes('coffee')) {
        suggestedCategory = 'food';
      } else if (description.includes('gas') || description.includes('fuel') || description.includes('uber') || description.includes('taxi')) {
        suggestedCategory = 'transport';
      } else if (description.includes('rent') || description.includes('housing') || description.includes('mortgage')) {
        suggestedCategory = 'housing';
      } else if (description.includes('electricity') || description.includes('water') || description.includes('internet')) {
        suggestedCategory = 'utilities';
      } else if (description.includes('medical') || description.includes('pharmacy') || description.includes('doctor')) {
        suggestedCategory = 'health';
      } else if (description.includes('entertainment') || description.includes('movie') || description.includes('netflix')) {
        suggestedCategory = 'entertainment';
      } else if (description.includes('education') || description.includes('course') || description.includes('book')) {
        suggestedCategory = 'education';
      } else if (description.includes('shopping') || description.includes('clothes') || description.includes('store')) {
        suggestedCategory = 'shopping';
      } else if (description.includes('savings') || description.includes('investment')) {
        suggestedCategory = 'savings';
      }
      
      setFormData(prev => ({ ...prev, category: suggestedCategory }));
    } catch (error) {
      console.error('Error categorizing:', error);
    } finally {
      setIsCategorizing(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.description || !formData.amount || !formData.category) return;

    const expense: Omit<Expense, 'id'> = {
      description: formData.description,
      amount: parseFloat(formData.amount),
      category: formData.category,
      date: formData.date,
      vendor: formData.vendor
    };

    onSubmit(expense);
    onClose();
  };

  const getCategoryIcon = (category: string) => {
    const icons: Record<string, string> = {
      food: '🍎',
      transport: '🚗',
      health: '🏥',
      housing: '🏠',
      utilities: '💡',
      shopping: '🛍️',
      entertainment: '🎬',
      education: '📚',
      savings: '💰',
      other: '📦'
    };
    return icons[category] || '📦';
  };

  console.log('ExpenseForm render - isOpen:', isOpen, 'editingExpense:', editingExpense);
  
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-red-500/80 z-[9999] flex items-center justify-center p-4"
          style={{ zIndex: 9999 }}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            className="bg-gradient-to-br from-purple-900 to-blue-900 rounded-2xl p-6 w-full max-w-md border border-white/20"
          >
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-white">
                {editingExpense ? 'Edit Expense' : 'Add New Expense'}
              </h2>
              <button
                onClick={onClose}
                className="p-2 hover:bg-white/10 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-white" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-purple-200 mb-2">
                  Description
                </label>
                <input
                  type="text"
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-purple-300 focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="e.g., Coffee at Tim Hortons"
                  required
                />
              </div>

              {/* Amount */}
              <div>
                <label className="block text-sm font-medium text-purple-200 mb-2">
                  Amount ($)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.amount}
                  onChange={(e) => setFormData(prev => ({ ...prev, amount: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-purple-300 focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="0.00"
                  required
                />
              </div>

              {/* Category */}
              <div>
                <label className="block text-sm font-medium text-purple-200 mb-2">
                  Category
                </label>
                <div className="flex space-x-2">
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
                    className="flex-1 px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                    required
                  >
                    <option value="">Select category</option>
                    {categories.map(category => (
                      <option key={category} value={category}>
                        {getCategoryIcon(category)} {category.charAt(0).toUpperCase() + category.slice(1)}
                      </option>
                    ))}
                  </select>
                  <motion.button
                    type="button"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={handleCategorize}
                    disabled={isCategorizing || !formData.description}
                    className="px-4 py-3 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-lg font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isCategorizing ? (
                      <Bot className="w-5 h-5 animate-spin" />
                    ) : (
                      '🤖'
                    )}
                  </motion.button>
                </div>
              </div>

              {/* Date */}
              <div>
                <label className="block text-sm font-medium text-purple-200 mb-2">
                  Date
                </label>
                <input
                  type="date"
                  value={formData.date}
                  onChange={(e) => setFormData(prev => ({ ...prev, date: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                />
              </div>

              {/* Vendor */}
              <div>
                <label className="block text-sm font-medium text-purple-200 mb-2">
                  Vendor (Optional)
                </label>
                <input
                  type="text"
                  value={formData.vendor}
                  onChange={(e) => setFormData(prev => ({ ...prev, vendor: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-purple-300 focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="e.g., Tim Hortons"
                />
              </div>

              {/* Submit Button */}
              <motion.button
                type="submit"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="w-full py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white rounded-lg font-medium flex items-center justify-center space-x-2"
              >
                <Save className="w-5 h-5" />
                <span>{editingExpense ? 'Update Expense' : 'Add Expense'}</span>
              </motion.button>
            </form>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default ExpenseForm;
