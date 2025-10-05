import React, { useState, useEffect } from 'react';
import { Plus, BarChart3, List, DollarSign } from 'lucide-react';
import './App.css';
import ExpenseList from './components/ExpenseList';
import AddExpense from './components/AddExpense';
import Summary from './components/Summary';
import { Expense, Summary as SummaryType } from './types';
import { expenseService } from './services/api';

type TabType = 'expenses' | 'add' | 'summary';

function App() {
  const [activeTab, setActiveTab] = useState<TabType>('expenses');
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [summary, setSummary] = useState<SummaryType | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [expensesData, summaryData] = await Promise.all([
        expenseService.getExpenses(),
        expenseService.getSummary()
      ]);
      setExpenses(expensesData);
      setSummary(summaryData);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleExpenseAdded = () => {
    fetchData();
    setActiveTab('expenses');
  };

  const handleDeleteExpense = async (id: number) => {
    try {
      await expenseService.deleteExpense(id);
      fetchData();
    } catch (error) {
      console.error('Error deleting expense:', error);
    }
  };

  const tabs = [
    { id: 'expenses' as TabType, label: 'Expenses', icon: List },
    { id: 'add' as TabType, label: 'Add Expense', icon: Plus },
    { id: 'summary' as TabType, label: 'Summary', icon: BarChart3 },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <DollarSign className="h-5 w-5 text-white" />
              </div>
              <h1 className="text-xl font-bold text-gray-900">Xubudget</h1>
            </div>
            <div className="text-sm text-gray-500">
              Canadian Financial Assistant
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center space-x-2 py-4 px-1 border-b-2 font-medium text-sm ${
                    activeTab === tab.id
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {activeTab === 'expenses' && (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-gray-900">Your Expenses</h2>
              <p className="text-gray-600">Manage and track your spending</p>
            </div>
            <ExpenseList
              expenses={expenses}
              onDelete={handleDeleteExpense}
              loading={loading}
            />
          </div>
        )}

        {activeTab === 'add' && (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-gray-900">Add New Expense</h2>
              <p className="text-gray-600">Track your spending with AI-powered categorization</p>
            </div>
            <AddExpense onExpenseAdded={handleExpenseAdded} />
          </div>
        )}

        {activeTab === 'summary' && (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-gray-900">Financial Summary</h2>
              <p className="text-gray-600">Visualize your spending patterns and trends</p>
            </div>
            {summary && <Summary summary={summary} loading={loading} />}
          </div>
        )}
      </main>
    </div>
  );
}

export default App;