import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip } from 'recharts';
import { Summary as SummaryType, CATEGORY_LABELS, CATEGORY_COLORS } from '../types';
import { formatCurrency } from '../utils/format';

interface SummaryProps {
  summary: SummaryType;
  loading?: boolean;
}

const Summary: React.FC<SummaryProps> = ({ summary, loading }) => {
  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const pieData = summary.categories.map(cat => ({
    name: CATEGORY_LABELS[cat.category] || cat.category,
    value: cat.total,
    color: CATEGORY_COLORS[cat.category] || '#6b7280'
  }));

  const barData = summary.categories.map(cat => ({
    name: CATEGORY_LABELS[cat.category] || cat.category,
    amount: cat.total,
    count: cat.count
  }));

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-blue-50 rounded-lg p-4">
          <h3 className="text-sm font-medium text-blue-600">Total Expenses</h3>
          <p className="text-2xl font-bold text-blue-900">{formatCurrency(summary.total_amount)}</p>
        </div>
        <div className="bg-green-50 rounded-lg p-4">
          <h3 className="text-sm font-medium text-green-600">Total Count</h3>
          <p className="text-2xl font-bold text-green-900">{summary.total_count}</p>
        </div>
        <div className="bg-purple-50 rounded-lg p-4">
          <h3 className="text-sm font-medium text-purple-600">Categories</h3>
          <p className="text-2xl font-bold text-purple-900">{summary.categories.length}</p>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Pie Chart */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Expenses by Category</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => formatCurrency(Number(value))} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Bar Chart */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Amount by Category</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="name" 
                  angle={-45}
                  textAnchor="end"
                  height={80}
                  fontSize={12}
                />
                <YAxis />
                <Tooltip formatter={(value) => formatCurrency(Number(value))} />
                <Bar dataKey="amount" fill="#3b82f6" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Category List */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Category Breakdown</h3>
        <div className="space-y-3">
          {summary.categories.map((category) => (
            <div key={category.category} className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div
                  className="w-4 h-4 rounded-full"
                  style={{ backgroundColor: CATEGORY_COLORS[category.category] }}
                />
                <span className="font-medium text-gray-900">
                  {CATEGORY_LABELS[category.category] || category.category}
                </span>
                <span className="text-sm text-gray-500">({category.count} items)</span>
              </div>
              <div className="text-right">
                <p className="font-semibold text-gray-900">{formatCurrency(category.total)}</p>
                <p className="text-sm text-gray-500">Avg: {formatCurrency(category.average)}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Summary;
