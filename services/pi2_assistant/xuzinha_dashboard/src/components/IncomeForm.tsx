import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, DollarSign } from 'lucide-react';

interface Income {
  id: string;
  description: string;
  amount: number;
  source: string;
  date: string;
  type: 'salary' | 'freelance' | 'investment' | 'other';
}

interface IncomeFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (income: Omit<Income, 'id'>) => void;
  editingIncome?: Income | null;
}

const IncomeForm: React.FC<IncomeFormProps> = ({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editingIncome 
}) => {
  const [formData, setFormData] = useState({
    description: '',
    amount: '',
    source: '',
    date: new Date().toISOString().split('T')[0],
    type: 'salary' as Income['type']
  });

  useEffect(() => {
    if (editingIncome) {
      setFormData({
        description: editingIncome.description,
        amount: editingIncome.amount.toString(),
        source: editingIncome.source,
        date: editingIncome.date,
        type: editingIncome.type
      });
    } else {
      setFormData({
        description: '',
        amount: '',
        source: '',
        date: new Date().toISOString().split('T')[0],
        type: 'salary'
      });
    }
  }, [editingIncome, isOpen]);

  const incomeTypes = [
    { value: 'salary', label: 'Salary', icon: '💼' },
    { value: 'freelance', label: 'Freelance', icon: '💻' },
    { value: 'investment', label: 'Investment', icon: '📈' },
    { value: 'other', label: 'Other', icon: '💰' }
  ];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.description || !formData.amount || !formData.source) return;

    const income: Omit<Income, 'id'> = {
      description: formData.description,
      amount: parseFloat(formData.amount),
      source: formData.source,
      date: formData.date,
      type: formData.type
    };

    onSubmit(income);
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            className="bg-gradient-to-br from-green-900 to-emerald-900 rounded-2xl p-6 w-full max-w-md border border-white/20"
          >
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-white">
                {editingIncome ? 'Edit Income' : 'Add New Income'}
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
                <label className="block text-sm font-medium text-green-200 mb-2">
                  Description
                </label>
                <input
                  type="text"
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-green-300 focus:outline-none focus:ring-2 focus:ring-green-500"
                  placeholder="e.g., Monthly Salary"
                  required
                />
              </div>

              {/* Amount */}
              <div>
                <label className="block text-sm font-medium text-green-200 mb-2">
                  Amount ($)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.amount}
                  onChange={(e) => setFormData(prev => ({ ...prev, amount: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-green-300 focus:outline-none focus:ring-2 focus:ring-green-500"
                  placeholder="0.00"
                  required
                />
              </div>

              {/* Source */}
              <div>
                <label className="block text-sm font-medium text-green-200 mb-2">
                  Source
                </label>
                <input
                  type="text"
                  value={formData.source}
                  onChange={(e) => setFormData(prev => ({ ...prev, source: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-green-300 focus:outline-none focus:ring-2 focus:ring-green-500"
                  placeholder="e.g., Company Name"
                  required
                />
              </div>

              {/* Type */}
              <div>
                <label className="block text-sm font-medium text-green-200 mb-2">
                  Income Type
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {incomeTypes.map(type => (
                    <motion.button
                      key={type.value}
                      type="button"
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => setFormData(prev => ({ ...prev, type: type.value as Income['type'] }))}
                      className={`p-3 rounded-lg border-2 transition-all ${
                        formData.type === type.value
                          ? 'border-green-400 bg-green-500/20 text-green-300'
                          : 'border-white/20 bg-white/5 text-white hover:bg-white/10'
                      }`}
                    >
                      <div className="text-center">
                        <div className="text-2xl mb-1">{type.icon}</div>
                        <div className="text-sm font-medium">{type.label}</div>
                      </div>
                    </motion.button>
                  ))}
                </div>
              </div>

              {/* Date */}
              <div>
                <label className="block text-sm font-medium text-green-200 mb-2">
                  Date
                </label>
                <input
                  type="date"
                  value={formData.date}
                  onChange={(e) => setFormData(prev => ({ ...prev, date: e.target.value }))}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-green-500"
                  required
                />
              </div>

              {/* Submit Button */}
              <motion.button
                type="submit"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="w-full py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white rounded-lg font-medium flex items-center justify-center space-x-2"
              >
                <DollarSign className="w-5 h-5" />
                <span>{editingIncome ? 'Update Income' : 'Add Income'}</span>
              </motion.button>
            </form>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default IncomeForm;
