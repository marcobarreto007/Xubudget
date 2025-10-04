import React from 'react';
import Dashboard from './components/Dashboard/Dashboard';
import { BudgetProvider } from './context/BudgetContext';
import './App.css';

function App() {
  return (
    <BudgetProvider>
      <Dashboard />
    </BudgetProvider>
  );
}

export default App;

