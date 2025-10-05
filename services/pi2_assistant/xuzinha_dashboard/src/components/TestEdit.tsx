import React, { useState } from 'react';

interface TestEditProps {
  expenses: any[];
  onUpdateExpense: (id: string, updatedExpense: any) => void;
}

const TestEdit: React.FC<TestEditProps> = ({ expenses, onUpdateExpense }) => {
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editData, setEditData] = useState({ description: '', amount: '' });

  const handleEdit = (expense: any) => {
    console.log('Starting edit for:', expense);
    setEditingId(expense.id);
    setEditData({
      description: expense.description,
      amount: expense.amount.toString()
    });
  };

  const handleSave = () => {
    if (editingId) {
      console.log('Saving edit for ID:', editingId, 'Data:', editData);
      onUpdateExpense(editingId, {
        ...expenses.find(e => e.id === editingId),
        description: editData.description,
        amount: parseFloat(editData.amount)
      });
      setEditingId(null);
      setEditData({ description: '', amount: '' });
    }
  };

  const handleCancel = () => {
    setEditingId(null);
    setEditData({ description: '', amount: '' });
  };

  return (
    <div className="p-4 bg-white/10 rounded-lg">
      <h3 className="text-white text-lg font-bold mb-4">Test Edit Component</h3>
      <div className="space-y-2">
        {expenses.map((expense) => (
          <div key={expense.id} className="flex items-center space-x-4 p-2 bg-white/5 rounded">
            {editingId === expense.id ? (
              <>
                <input
                  type="text"
                  value={editData.description}
                  onChange={(e) => setEditData(prev => ({ ...prev, description: e.target.value }))}
                  className="px-2 py-1 bg-white/20 text-white rounded"
                />
                <input
                  type="number"
                  value={editData.amount}
                  onChange={(e) => setEditData(prev => ({ ...prev, amount: e.target.value }))}
                  className="px-2 py-1 bg-white/20 text-white rounded w-20"
                />
                <button
                  onClick={handleSave}
                  className="px-3 py-1 bg-green-500 text-white rounded text-sm"
                >
                  Save
                </button>
                <button
                  onClick={handleCancel}
                  className="px-3 py-1 bg-red-500 text-white rounded text-sm"
                >
                  Cancel
                </button>
              </>
            ) : (
              <>
                <span className="text-white">{expense.description}</span>
                <span className="text-white">${expense.amount}</span>
                <button
                  onClick={() => handleEdit(expense)}
                  className="px-3 py-1 bg-blue-500 text-white rounded text-sm"
                >
                  Edit
                </button>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default TestEdit;
