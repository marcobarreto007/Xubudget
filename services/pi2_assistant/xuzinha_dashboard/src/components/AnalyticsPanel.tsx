import React from 'react';
import { motion } from 'framer-motion';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { TrendingUp, TrendingDown, DollarSign, Calendar, Target } from 'lucide-react';

interface Expense {
  id: string;
  description: string;
  amount: number;
  category: string;
  date: string;
  receiptImage?: string;
  vendor?: string;
}

interface AnalyticsPanelProps {
  expenses: Expense[];
}

const AnalyticsPanel: React.FC<AnalyticsPanelProps> = ({ expenses }) => {
  const totalSpent = expenses.reduce((sum, expense) => sum + expense.amount, 0);
  const averageExpense = expenses.length > 0 ? totalSpent / expenses.length : 0;

  // Category data for charts
  const categoryTotals = expenses.reduce((acc, expense) => {
    acc[expense.category] = (acc[expense.category] || 0) + expense.amount;
    return acc;
  }, {} as Record<string, number>);

  const pieData = Object.entries(categoryTotals).map(([category, amount]) => ({
    name: category,
    value: amount,
    color: getCategoryColor(category)
  }));

  // Removed unused barData variable

  // Monthly spending data (mock data for demo)
  const monthlyData = [
    { month: 'Jan', amount: 1200 },
    { month: 'Feb', amount: 1500 },
    { month: 'Mar', amount: 1800 },
    { month: 'Apr', amount: 1600 },
    { month: 'May', amount: 2000 },
    { month: 'Jun', amount: 1700 }
  ];

  function getCategoryColor(category: string) {
    const colors = {
      food: '#ef4444',
      transport: '#3b82f6',
      health: '#10b981',
      housing: '#8b5cf6',
      utilities: '#f59e0b',
      shopping: '#ec4899',
      entertainment: '#6366f1',
      education: '#06b6d4',
      savings: '#059669',
      other: '#6b7280'
    };
    return colors[category as keyof typeof colors] || colors.other;
  }

  const COLORS = ['#ef4444', '#3b82f6', '#10b981', '#8b5cf6', '#f59e0b', '#ec4899', '#6366f1', '#06b6d4', '#059669', '#6b7280'];

  return (
    <div className="space-y-6">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex items-center justify-between"
      >
        <div>
          <h2 className="text-2xl font-bold text-white">Analytics & Insights</h2>
          <p className="text-purple-200">Understand your spending patterns</p>
        </div>
      </motion.div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="glass rounded-2xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-lg flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-white" />
            </div>
            <TrendingUp className="w-6 h-6 text-green-400" />
          </div>
          <h3 className="text-white font-semibold mb-2">Total Spent</h3>
          <p className="text-3xl font-bold text-white">${totalSpent.toLocaleString()}</p>
          <p className="text-blue-200 text-sm mt-1">This month</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="glass rounded-2xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-emerald-500 rounded-lg flex items-center justify-center">
              <Target className="w-6 h-6 text-white" />
            </div>
            <TrendingUp className="w-6 h-6 text-green-400" />
          </div>
          <h3 className="text-white font-semibold mb-2">Average Expense</h3>
          <p className="text-3xl font-bold text-white">${averageExpense.toFixed(2)}</p>
          <p className="text-green-200 text-sm mt-1">Per transaction</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="glass rounded-2xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg flex items-center justify-center">
              <Calendar className="w-6 h-6 text-white" />
            </div>
            <TrendingDown className="w-6 h-6 text-red-400" />
          </div>
          <h3 className="text-white font-semibold mb-2">Transactions</h3>
          <p className="text-3xl font-bold text-white">{expenses.length}</p>
          <p className="text-purple-200 text-sm mt-1">This month</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="glass rounded-2xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-white" />
            </div>
            <TrendingUp className="w-6 h-6 text-green-400" />
          </div>
          <h3 className="text-white font-semibold mb-2">Top Category</h3>
          <p className="text-3xl font-bold text-white">
            {Object.entries(categoryTotals).length > 0 
              ? Object.entries(categoryTotals).sort(([,a], [,b]) => b - a)[0][0].charAt(0).toUpperCase() + 
                Object.entries(categoryTotals).sort(([,a], [,b]) => b - a)[0][0].slice(1)
              : 'N/A'
            }
          </p>
          <p className="text-orange-200 text-sm mt-1">Highest spending</p>
        </motion.div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Category Distribution Pie Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="glass rounded-2xl p-6"
        >
          <h3 className="text-white font-semibold mb-6">Spending by Category</h3>
          {pieData.length > 0 ? (
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }: any) => `${name} ${((percent as number) * 100).toFixed(0)}%`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: any) => `$${(value as number).toFixed(2)}`} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div className="h-80 flex items-center justify-center">
              <div className="text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center mx-auto mb-4">
                  <BarChart className="w-8 h-8 text-white" />
                </div>
                <p className="text-purple-200">No data to display</p>
                <p className="text-purple-300 text-sm">Add some expenses to see analytics</p>
              </div>
            </div>
          )}
        </motion.div>

        {/* Monthly Spending Bar Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="glass rounded-2xl p-6"
        >
          <h3 className="text-white font-semibold mb-6">Monthly Spending Trend</h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="month" stroke="#9ca3af" />
                <YAxis stroke="#9ca3af" />
                <Tooltip 
                  formatter={(value) => [`$${value.toLocaleString()}`, 'Amount']}
                  contentStyle={{ 
                    backgroundColor: '#1f2937', 
                    border: '1px solid #6b7280', 
                    borderRadius: '8px',
                    color: '#ffffff'
                  }}
                />
                <Bar dataKey="amount" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </motion.div>
      </div>

      {/* Category Breakdown */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.7 }}
        className="glass rounded-2xl p-6"
      >
        <h3 className="text-white font-semibold mb-6">Category Breakdown</h3>
        <div className="space-y-4">
          {Object.entries(categoryTotals)
            .sort(([,a], [,b]) => b - a)
            .map(([category, amount], index) => (
              <div key={category} className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div 
                    className="w-4 h-4 rounded-full"
                    style={{ backgroundColor: COLORS[index % COLORS.length] }}
                  />
                  <span className="text-white capitalize font-medium">{category}</span>
                </div>
                <div className="text-right">
                  <p className="text-white font-semibold">${amount.toLocaleString()}</p>
                  <p className="text-purple-200 text-sm">
                    {((amount / totalSpent) * 100).toFixed(1)}%
                  </p>
                </div>
              </div>
            ))}
        </div>
      </motion.div>
    </div>
  );
};

export default AnalyticsPanel;
