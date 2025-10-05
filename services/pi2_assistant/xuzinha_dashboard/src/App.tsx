import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Camera, 
  Receipt, 
  Bot, 
  BarChart3,
  Wallet,
  Target
} from 'lucide-react';
import { backendSyncService } from './services/backendSync';

// Components
import XuzinhaAvatar from './components/XuzinhaAvatar';
import ReceiptCapture from './components/ReceiptCapture';
import ChatInterface from './components/ChatInterface';
import ExpenseForm from './components/ExpenseForm';
import IncomeForm from './components/IncomeForm';
import BudgetOverview from './components/BudgetOverview';
import ExpenseList from './components/ExpenseList';
import GoalsWidget from './components/GoalsWidget';
import AnalyticsPanel from './components/AnalyticsPanel';
import FloatingCommandBar from './components/FloatingCommandBar';

// Types
interface Expense {
  id: string;
  description: string;
  amount: number;
  category: string;
  date: string;
  receiptImage?: string;
  vendor?: string;
}

interface XuzinhaState {
  isActive: boolean;
  isProcessing: boolean;
  currentMessage: string;
  mood: 'happy' | 'focused' | 'processing' | 'sleeping';
}

const App: React.FC = () => {
  const [xuzinhaState, setXuzinhaState] = useState<XuzinhaState>({
    isActive: true,
    isProcessing: false,
    currentMessage: "Hello! I'm Xuzinha, your AI financial assistant. I'm here to help you manage your finances!",
    mood: 'happy'
  });

  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [incomes, setIncomes] = useState<any[]>([]);
  const [totalBudget, setTotalBudget] = useState(4000);
  const [totalSpent, setTotalSpent] = useState(0);
  const [remaining, setRemaining] = useState(4000);

  // Budget and Income System - Weekly Income
  const [weeklyIncome] = useState(800); // Weekly income
  const [governmentAssistance] = useState(200); // Weekly government assistance
  const [totalWeeklyIncome] = useState(1000); // Total weekly income
  const [monthlyIncome] = useState(4000); // Monthly income
  
  const [budgets] = useState({
    food: 400,
    transport: 200,
    health: 150,
    housing: 1200,
    utilities: 300,
    shopping: 200,
    entertainment: 150,
    education: 100,
    savings: 500,
    other: 100
  });
  const [showReceiptCapture, setShowReceiptCapture] = useState(false);
  const [showChat, setShowChat] = useState(false);
  const [activePanel, setActivePanel] = useState<'overview' | 'expenses' | 'goals' | 'analytics' | 'manage'>('overview');
  const [showAddExpense, setShowAddExpense] = useState(false);
  const [showAddIncome, setShowAddIncome] = useState(false);
  const [editingExpense, setEditingExpense] = useState<Expense | null>(null);

  // Calculate financial data
  const calculatedTotalSpent = expenses.reduce((sum, expense) => sum + expense.amount, 0);
  const remainingBudget = monthlyIncome - calculatedTotalSpent;

  // Load initial data from backend
  useEffect(() => {
    const loadInitialData = async () => {
      try {
        const backendState = await backendSyncService.getCurrentState('default');
        const frontendData = backendSyncService.convertBackendToFrontend(backendState);
        
        setExpenses(frontendData.expenses);
        setTotalBudget(frontendData.totalBudget);
        setTotalSpent(frontendData.totalSpent);
        setRemaining(frontendData.remaining);
      } catch (error) {
        console.error('Failed to load initial data:', error);
      }
    };

    loadInitialData();
  }, []);

  // Handle sync commands from chat
  const handleCommand = (command: string) => {
    if (command.startsWith('SYNC:')) {
      try {
        const syncData = JSON.parse(command.substring(5));
        setExpenses(syncData.expenses || []);
        setTotalBudget(syncData.totalBudget || 4000);
        setTotalSpent(syncData.totalSpent || 0);
        setRemaining(syncData.remaining || 4000);
      } catch (error) {
        console.error('Failed to parse sync data:', error);
      }
    }
  };

  // Expense management functions
  const handleAddExpense = (newExpense: Omit<Expense, 'id'>) => {
    const expense: Expense = {
      ...newExpense,
      id: Date.now().toString(),
      date: newExpense.date || new Date().toISOString().split('T')[0]
    };
    setExpenses(prev => [...prev, expense]);
    setShowAddExpense(false);
  };

  const handleEditExpense = (updatedExpense: Expense) => {
    setExpenses(prev => prev.map(expense => 
      expense.id === updatedExpense.id ? updatedExpense : expense
    ));
    setEditingExpense(null);
  };

  const handleDeleteExpense = (expenseId: string) => {
    setExpenses(prev => prev.filter(expense => expense.id !== expenseId));
  };

  const handleEditClick = (expense: Expense) => {
    console.log('handleEditClick called with expense:', expense);
    setEditingExpense(expense);
    setShowAddExpense(true);
    console.log('editingExpense set to:', expense);
    console.log('showAddExpense set to: true');
  };
  
  const categorySpent = expenses.reduce((acc, expense) => {
    acc[expense.category] = (acc[expense.category] || 0) + expense.amount;
    return acc;
  }, {} as Record<string, number>);

  const categoryRemaining = Object.entries(budgets).map(([category, budget]) => ({
    category,
    budget,
    spent: categorySpent[category] || 0,
    remaining: budget - (categorySpent[category] || 0),
    percentage: ((categorySpent[category] || 0) / budget) * 100
  }));

  // Simulate Xuzinha processing
  useEffect(() => {
    if (xuzinhaState.isProcessing) {
      const xuzinhaMessages = [
        "I've captured that receipt for you — want me to assign the category?",
        "Your spending looks great this month!",
        "I noticed you bought coffee again — should I add it to your daily budget?",
        "Xuzinha is scanning receipts…",
        "I'm analyzing your financial patterns...",
        "Ready to help you save more!"
      ];

      const interval = setInterval(() => {
        const randomMessage = xuzinhaMessages[Math.floor(Math.random() * xuzinhaMessages.length)];
        setXuzinhaState(prev => ({
          ...prev,
          currentMessage: randomMessage,
          mood: 'processing'
        }));
      }, 3000);

      return () => clearInterval(interval);
    }
  }, [xuzinhaState.isProcessing]);

  const handleReceiptCapture = (receiptData: any) => {
    setXuzinhaState(prev => ({
      ...prev,
      isProcessing: true,
      currentMessage: "Processing your receipt...",
      mood: 'processing'
    }));

    // Simulate OCR processing
    setTimeout(() => {
      const newExpense: Expense = {
        id: Date.now().toString(),
        description: receiptData.description || "Receipt from store",
        amount: receiptData.amount || 0,
        category: receiptData.category || "other",
        date: new Date().toISOString().split('T')[0],
        receiptImage: receiptData.image,
        vendor: receiptData.vendor || "Unknown Store"
      };

      setExpenses(prev => [newExpense, ...prev]);
      setXuzinhaState(prev => ({
        ...prev,
        isProcessing: false,
        currentMessage: "Receipt processed! I've added it to your expenses 💜",
        mood: 'happy'
      }));
    }, 2000);
  };

  const handleXuzinhaCommand = (command: string) => {
    setXuzinhaState(prev => ({
      ...prev,
      isProcessing: true,
      currentMessage: "I'm on it!",
      mood: 'focused'
    }));

    switch (command) {
      case 'scan_receipt':
        setShowReceiptCapture(true);
        break;
      case 'show_analytics':
        setActivePanel('analytics');
        break;
      case 'check_budget':
        setActivePanel('overview');
        break;
      default:
        setXuzinhaState(prev => ({
          ...prev,
          isProcessing: false,
          currentMessage: "I'm not sure what you mean, but I'm here to help! 💜",
          mood: 'happy'
        }));
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
      {/* Background Effects */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-float"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-pink-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-float" style={{ animationDelay: '2s' }}></div>
        <div className="absolute top-40 left-1/2 w-80 h-80 bg-cyan-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-float" style={{ animationDelay: '4s' }}></div>
      </div>

      {/* Header */}
      <motion.header 
        initial={{ y: -100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="relative z-10 p-6"
      >
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          {/* Logo & Title */}
          <div className="flex items-center space-x-4">
            <motion.div
              animate={{ rotate: [0, 10, -10, 0] }}
              transition={{ duration: 2, repeat: Infinity, repeatDelay: 3 }}
              className="relative"
            >
              {/* Xuzinha Avatar - Cyberpunk Image */}
              <div className="relative w-12 h-12">
                {/* Outer Glow Ring */}
                <div className="absolute inset-0 rounded-full bg-gradient-to-r from-cyan-400 via-purple-400 to-pink-400 p-0.5">
                  <div className="w-full h-full rounded-full bg-black/90 flex items-center justify-center overflow-hidden">
                    {/* Cyberpunk Image Avatar */}
                    <img 
                      src="/images/xuzinha/xuzinha_avatar.png" 
                      alt="Xuzinha Cyberpunk Avatar"
                      className="w-full h-full object-cover rounded-full"
                      onError={(e) => {
                        // Fallback to generated avatar if image not found
                        e.currentTarget.style.display = 'none';
                        const fallback = e.currentTarget.nextElementSibling as HTMLElement;
                        if (fallback) {
                          fallback.style.display = 'block';
                        }
                      }}
                    />
                    
                    {/* Fallback Generated Avatar */}
                    <div className="relative w-full h-full rounded-full overflow-hidden" style={{ display: 'none' }}>
                      {/* Face Base */}
                      <div className="absolute inset-0 bg-gradient-to-br from-gray-100 to-gray-200 rounded-full">
                        {/* Hair with Circuitry */}
                        <div className="absolute -top-1 left-0 right-0 h-4 bg-gradient-to-b from-gray-800 to-gray-900 rounded-t-full">
                          {/* Circuitry Lines in Hair */}
                          <div className="absolute top-1 left-1 right-1 h-px bg-cyan-400"></div>
                          <div className="absolute top-1.5 left-2 right-2 h-px bg-purple-400"></div>
                          <div className="absolute top-2 left-1 right-1 h-px bg-pink-400"></div>
                        </div>
                        
                        {/* Eyes */}
                        <div className="absolute top-2.5 left-2 w-1 h-1 bg-cyan-400 rounded-full"></div>
                        <div className="absolute top-2.5 right-2 w-1 h-1 bg-cyan-400 rounded-full"></div>
                        
                        {/* Glasses Frame */}
                        <div className="absolute top-2 left-1 right-1 h-2 border-2 border-cyan-400 rounded-full"></div>
                        <div className="absolute top-2 left-1/2 w-px h-2 bg-cyan-400"></div>
                        
                        {/* Nose */}
                        <div className="absolute top-4 left-1/2 w-0.5 h-0.5 bg-gray-300 rounded-full transform -translate-x-1/2"></div>
                        
                        {/* Smile */}
                        <div className="absolute bottom-2 left-1 right-1 h-0.5 border-b-2 border-cyan-400 rounded-full"></div>
                        
                        {/* Circuitry on Face */}
                        <div className="absolute top-3 left-0 right-0 h-px bg-cyan-400/60"></div>
                        <div className="absolute bottom-2.5 left-0 right-0 h-px bg-purple-400/60"></div>
                        
                        {/* Metallic Plates */}
                        <div className="absolute top-1.5 left-1 w-1 h-1 bg-gray-400 rounded-sm opacity-60"></div>
                        <div className="absolute top-1.5 right-1 w-1 h-1 bg-gray-400 rounded-sm opacity-60"></div>
                      </div>
                      
                      {/* Glow Effect */}
                      <div className="absolute inset-0 rounded-full bg-gradient-to-r from-cyan-400/20 via-purple-400/20 to-pink-400/20 animate-pulse"></div>
                    </div>
                  </div>
                </div>
                
                {/* Floating Particles */}
                <div className="absolute -top-1 -right-1 w-1 h-1 bg-cyan-400 rounded-full animate-ping"></div>
                <div className="absolute -bottom-1 -left-1 w-0.5 h-0.5 bg-purple-400 rounded-full animate-pulse"></div>
                <div className="absolute top-1 -left-1 w-0.5 h-0.5 bg-pink-400 rounded-full animate-pulse"></div>
              </div>
            </motion.div>
            <div>
              <h1 className="text-2xl font-bold text-white">XUBUDGET AI</h1>
              <p className="text-purple-200 text-sm">Created by Marco Barreto for Xuzinha, his love</p>
            </div>
          </div>

          {/* Xuzinha Status */}
          <div className="flex items-center space-x-4">
            <XuzinhaAvatar 
              state={xuzinhaState}
              onClick={() => {
                console.log('Xuzinha clicked! Current showChat:', showChat);
                setShowChat(!showChat);
                console.log('showChat set to:', !showChat);
              }}
            />
            <div className="text-right">
              <p className="text-white font-medium">Xuzinha is {xuzinhaState.mood}</p>
              <p className="text-purple-200 text-sm">{xuzinhaState.currentMessage}</p>
              {showChat && (
                <p className="text-cyan-400 text-xs font-bold">💬 CHAT ACTIVE</p>
              )}
            </div>
          </div>
        </div>
      </motion.header>

      {/* Main Content */}
      <main className="relative z-10 px-6 pb-20">
        <div className="max-w-7xl mx-auto">
          {/* Navigation Tabs */}
          <motion.nav 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex space-x-2 mb-8"
          >
            {[
              { id: 'overview', label: 'Overview', icon: BarChart3 },
              { id: 'expenses', label: 'Expenses', icon: Receipt },
              { id: 'goals', label: 'Goals', icon: Target },
              { id: 'analytics', label: 'Analytics', icon: Wallet },
              { id: 'manage', label: 'Manage', icon: Wallet }
            ].map((tab) => {
              const Icon = tab.icon;
              return (
                <motion.button
                  key={tab.id}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => setActivePanel(tab.id as any)}
                  className={`flex items-center space-x-2 px-6 py-3 rounded-full transition-all duration-300 ${
                    activePanel === tab.id
                      ? 'bg-white text-purple-900 shadow-lg'
                      : 'glass text-white hover:bg-white/20'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span className="font-medium">{tab.label}</span>
                </motion.button>
              );
            })}
          </motion.nav>

          {/* Content Panels */}
          <AnimatePresence mode="wait">
            <motion.div
              key={activePanel}
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.3 }}
            >
              {activePanel === 'overview' && (
                <BudgetOverview 
                  expenses={expenses} 
                  monthlyIncome={monthlyIncome}
                  weeklyIncome={weeklyIncome}
                  governmentAssistance={governmentAssistance}
                  totalWeeklyIncome={totalWeeklyIncome}
                  budgets={budgets}
                  categoryRemaining={categoryRemaining}
                  totalSpent={totalSpent}
                  remainingBudget={remainingBudget}
                />
              )}
              {activePanel === 'expenses' && (
                <ExpenseList 
                  expenses={expenses} 
                  onReceiptClick={() => setShowReceiptCapture(true)}
                />
              )}
              {activePanel === 'goals' && (
                <GoalsWidget />
              )}
              {activePanel === 'analytics' && (
                <AnalyticsPanel expenses={expenses} />
              )}
              {activePanel === 'manage' && (
                <div className="space-y-6">
                  {/* Header with Income Summary */}
                  <div className="glass rounded-2xl p-6">
                    <div className="flex justify-between items-center mb-4">
                      <h2 className="text-2xl font-bold text-white">Financial Management</h2>
                      <div className="text-right">
                        <p className="text-white text-lg font-semibold">Weekly Income: ${totalWeeklyIncome.toLocaleString()}</p>
                        <p className="text-purple-200 text-sm">${weeklyIncome} salary + ${governmentAssistance} government</p>
                      </div>
                    </div>
                    
                    <div className="flex space-x-3">
                      <motion.button
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setShowAddExpense(true)}
                        className="px-6 py-3 bg-gradient-to-r from-red-500 to-pink-500 text-white rounded-full font-medium shadow-lg flex items-center space-x-2"
                      >
                        <span>💸</span>
                        <span>Add Expense</span>
                      </motion.button>
                      <motion.button
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setShowAddIncome(true)}
                        className="px-6 py-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white rounded-full font-medium shadow-lg flex items-center space-x-2"
                      >
                        <span>💰</span>
                        <span>Add Income</span>
                      </motion.button>
                    </div>
                  </div>
                  
                  {/* Quick Stats */}
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="glass rounded-xl p-4 text-center">
                      <p className="text-purple-200 text-sm">This Week Spent</p>
                      <p className="text-white text-2xl font-bold">${totalSpent.toFixed(2)}</p>
                    </div>
                    <div className="glass rounded-xl p-4 text-center">
                      <p className="text-purple-200 text-sm">Weekly Budget</p>
                      <p className="text-white text-2xl font-bold">${monthlyIncome.toFixed(2)}</p>
                    </div>
                    <div className="glass rounded-xl p-4 text-center">
                      <p className="text-purple-200 text-sm">Remaining</p>
                      <p className="text-white text-2xl font-bold">${remainingBudget.toFixed(2)}</p>
                    </div>
                  </div>
                  
                  {/* Expenses List with Better UI */}
                  <div className="glass rounded-2xl p-6">
                    <div className="flex justify-between items-center mb-6">
                      <h3 className="text-xl font-bold text-white">All Expenses ({expenses.length})</h3>
                      <div className="flex space-x-2">
                        <button className="px-3 py-1 bg-purple-500/20 text-purple-300 rounded-full text-sm">
                          All
                        </button>
                        <button className="px-3 py-1 bg-white/10 text-white rounded-full text-sm">
                          This Week
                        </button>
                        <button className="px-3 py-1 bg-white/10 text-white rounded-full text-sm">
                          This Month
                        </button>
                      </div>
                    </div>
                    
                    <div className="space-y-3">
                      {expenses.map((expense, index) => (
                        <motion.div 
                          key={expense.id}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: index * 0.1 }}
                          className="flex items-center justify-between p-4 bg-white/5 rounded-xl hover:bg-white/10 transition-all duration-200"
                        >
                          <div className="flex items-center space-x-4">
                            <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg flex items-center justify-center">
                              <span className="text-white text-lg">
                                {expense.category === 'food' ? '🍎' : 
                                 expense.category === 'transport' ? '🚗' :
                                 expense.category === 'health' ? '🏥' :
                                 expense.category === 'housing' ? '🏠' :
                                 expense.category === 'utilities' ? '💡' :
                                 expense.category === 'shopping' ? '🛍️' :
                                 expense.category === 'entertainment' ? '🎬' :
                                 expense.category === 'education' ? '📚' :
                                 expense.category === 'savings' ? '💰' : '📦'}
                              </span>
                            </div>
                            <div>
                              <p className="text-white font-medium">{expense.description}</p>
                              <p className="text-purple-200 text-sm capitalize">
                                {expense.category} • {new Date(expense.date).toLocaleDateString('en-CA')}
                                {expense.vendor && ` • ${expense.vendor}`}
                              </p>
                            </div>
                          </div>
                          <div className="flex items-center space-x-3">
                            <div className="text-right">
                              <p className="text-white font-bold text-lg">${expense.amount.toFixed(2)}</p>
                              <p className="text-purple-200 text-xs">
                                {budgets[expense.category as keyof typeof budgets] ? 
                                  `${((expense.amount / budgets[expense.category as keyof typeof budgets]) * 100).toFixed(1)}% of budget` : 
                                  'No budget set'
                                }
                              </p>
                            </div>
                            <div className="flex space-x-2">
                              <motion.button
                                whileHover={{ scale: 1.1 }}
                                whileTap={{ scale: 0.9 }}
                                onClick={() => handleEditClick(expense)}
                                className="p-2 bg-blue-500/20 text-blue-300 rounded-lg hover:bg-blue-500/30 transition-colors"
                                title="Edit expense"
                              >
                                ✏️
                              </motion.button>
                              <motion.button
                                whileHover={{ scale: 1.1 }}
                                whileTap={{ scale: 0.9 }}
                                onClick={() => handleDeleteExpense(expense.id)}
                                className="p-2 bg-red-500/20 text-red-300 rounded-lg hover:bg-red-500/30 transition-colors"
                                title="Delete expense"
                              >
                                🗑️
                              </motion.button>
                            </div>
                          </div>
                        </motion.div>
                      ))}
                      
                      {expenses.length === 0 && (
                        <div className="text-center py-12">
                          <div className="text-6xl mb-4">📝</div>
                          <p className="text-white text-xl font-medium mb-2">No expenses yet</p>
                          <p className="text-purple-200">Add your first expense to get started!</p>
                        </div>
                      )}
                    </div>
                  </div>
                  
                  {/* Debug Info */}
                  <div className="glass rounded-2xl p-6">
                    <h3 className="text-xl font-bold text-white mb-4">Debug Info</h3>
                    <div className="text-white text-sm space-y-2">
                      <p>Total expenses: {expenses.length}</p>
                      <p>Editing expense: {editingExpense ? editingExpense.description : 'None'}</p>
                      <p>Show add expense: {showAddExpense ? 'Yes' : 'No'}</p>
                      <div className="mt-4 space-x-2">
                        <button
                          onClick={() => {
                            console.log('Test button clicked');
                            console.log('Current expenses:', expenses);
                            console.log('Editing expense:', editingExpense);
                            console.log('Show add expense:', showAddExpense);
                          }}
                          className="px-4 py-2 bg-purple-500 text-white rounded"
                        >
                          Test Console Log
                        </button>
                        <button
                          onClick={() => {
                            console.log('Testing edit click');
                            if (expenses.length > 0) {
                              const firstExpense = expenses[0];
                              console.log('Editing first expense:', firstExpense);
                              handleEditClick(firstExpense);
                            } else {
                              console.log('No expenses to edit');
                            }
                          }}
                          className="px-4 py-2 bg-green-500 text-white rounded"
                        >
                          Test Edit Click
                        </button>
                        <button
                          onClick={() => {
                            console.log('Testing add expense');
                            setShowAddExpense(true);
                            setEditingExpense(null);
                            console.log('showAddExpense set to true');
                          }}
                          className="px-4 py-2 bg-blue-500 text-white rounded"
                        >
                          Test Add Expense
                        </button>
                        <button
                          onClick={() => {
                            console.log('Force opening modal');
                            setShowAddExpense(true);
                            setEditingExpense({
                              id: 'test',
                              description: 'Test Expense',
                              amount: 100,
                              category: 'food',
                              date: '2024-01-01',
                              vendor: 'Test Vendor'
                            });
                            console.log('Modal should be open now');
                          }}
                          className="px-4 py-2 bg-red-500 text-white rounded"
                        >
                          Force Open Modal
                        </button>
                        <button
                          onClick={() => {
                            console.log('Testing chat toggle');
                            setShowChat(!showChat);
                            console.log('showChat set to:', !showChat);
                          }}
                          className={`px-6 py-3 text-white rounded-lg font-bold transition-all ${
                            showChat 
                              ? 'bg-green-500 hover:bg-green-600' 
                              : 'bg-yellow-500 hover:bg-yellow-600'
                          }`}
                        >
                          {showChat ? '💬 CHAT OPEN' : '🤖 OPEN CHAT'}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </motion.div>
          </AnimatePresence>
        </div>
      </main>

      {/* Floating Action Button */}
      <motion.button
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        onClick={() => setShowReceiptCapture(true)}
        className="fab"
      >
        <Camera className="w-6 h-6 text-white" />
      </motion.button>

      {/* Floating Command Bar */}
      <FloatingCommandBar onCommand={handleXuzinhaCommand} />

      {/* Modals */}
      <AnimatePresence>
        {showReceiptCapture && (
          <ReceiptCapture
            onClose={() => setShowReceiptCapture(false)}
            onCapture={handleReceiptCapture}
          />
        )}
        {showChat && (
          <ChatInterface
            onClose={() => {
              console.log('Closing chat');
              setShowChat(false);
            }}
            xuzinhaState={xuzinhaState}
            onCommand={handleCommand}
            expenses={expenses}
            onExpensesChange={setExpenses}
            monthlyIncome={monthlyIncome}
            weeklyIncome={weeklyIncome}
            governmentAssistance={governmentAssistance}
            totalWeeklyIncome={totalWeeklyIncome}
            budgets={budgets}
            categoryRemaining={categoryRemaining}
            totalSpent={totalSpent}
            remainingBudget={remainingBudget}
          />
        )}
      </AnimatePresence>

      {/* Footer Status */}
      <motion.footer 
        initial={{ y: 100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="fixed bottom-0 left-0 right-0 z-10 p-4"
      >
        <div className="max-w-7xl mx-auto">
          <div className="glass rounded-lg p-3 flex items-center justify-center space-x-2">
            <div className="xuzinha-loading"></div>
            <span className="text-white text-sm">
              {xuzinhaState.isProcessing ? xuzinhaState.currentMessage : "Xuzinha is ready to help"}
            </span>
          </div>
        </div>
      </motion.footer>

      {/* Expense Form Modal */}
      <ExpenseForm
        isOpen={showAddExpense}
        onClose={() => {
          setShowAddExpense(false);
          setEditingExpense(null);
        }}
        onSubmit={editingExpense ? 
          (expense) => handleEditExpense({ ...expense, id: editingExpense.id }) : 
          handleAddExpense
        }
        editingExpense={editingExpense}
        budgets={budgets}
      />

      {/* Income Form Modal */}
      <IncomeForm
        isOpen={showAddIncome}
        onClose={() => setShowAddIncome(false)}
        onSubmit={(income) => {
          // For now, we'll just close the form
          // In a real app, you'd add this to an income state
          console.log('Income added:', income);
          setShowAddIncome(false);
        }}
      />
    </div>
  );
};

export default App;