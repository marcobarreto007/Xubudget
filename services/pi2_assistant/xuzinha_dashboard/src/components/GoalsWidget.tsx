import React from 'react';
import { motion } from 'framer-motion';
import { Target, Plus, Calendar, DollarSign } from 'lucide-react';

const GoalsWidget: React.FC = () => {
  const goals = [
    {
      id: '1',
      title: 'Emergency Fund',
      target: 10000,
      current: 3500,
      deadline: '2024-12-31',
      priority: 'high',
      icon: '🛡️'
    },
    {
      id: '2',
      title: 'Vacation Fund',
      target: 5000,
      current: 1200,
      deadline: '2024-08-15',
      priority: 'medium',
      icon: '✈️'
    },
    {
      id: '3',
      title: 'New Laptop',
      target: 2000,
      current: 800,
      deadline: '2024-06-30',
      priority: 'low',
      icon: '💻'
    }
  ];

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'from-red-500 to-pink-500';
      case 'medium':
        return 'from-yellow-500 to-orange-500';
      case 'low':
        return 'from-green-500 to-emerald-500';
      default:
        return 'from-gray-500 to-slate-500';
    }
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
          <h2 className="text-2xl font-bold text-white">Financial Goals</h2>
          <p className="text-purple-200">Track your savings progress</p>
        </div>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-medium flex items-center space-x-2"
        >
          <Plus className="w-5 h-5" />
          <span>Add Goal</span>
        </motion.button>
      </motion.div>

      {/* Goals List */}
      <div className="space-y-4">
        {goals.map((goal, index) => {
          const progress = (goal.current / goal.target) * 100;
          const daysLeft = Math.ceil((new Date(goal.deadline).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24));
          
          return (
            <motion.div
              key={goal.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="glass rounded-2xl p-6 hover:bg-white/10 transition-all duration-300"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center space-x-4">
                  <div className="text-4xl">{goal.icon}</div>
                  <div>
                    <h3 className="text-white font-semibold text-lg">{goal.title}</h3>
                    <div className="flex items-center space-x-4 mt-1">
                      <div className="flex items-center space-x-1 text-purple-200 text-sm">
                        <DollarSign className="w-4 h-4" />
                        <span>${goal.current.toLocaleString()} / ${goal.target.toLocaleString()}</span>
                      </div>
                      <div className="flex items-center space-x-1 text-purple-200 text-sm">
                        <Calendar className="w-4 h-4" />
                        <span>{daysLeft} days left</span>
                      </div>
                    </div>
                  </div>
                </div>
                <div className={`px-3 py-1 rounded-full text-xs font-medium ${
                  goal.priority === 'high' ? 'bg-red-500/20 text-red-300' :
                  goal.priority === 'medium' ? 'bg-yellow-500/20 text-yellow-300' :
                  'bg-green-500/20 text-green-300'
                }`}>
                  {goal.priority.toUpperCase()}
                </div>
              </div>

              {/* Progress Bar */}
              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-white font-medium">Progress</span>
                  <span className="text-purple-200 text-sm">{progress.toFixed(1)}%</span>
                </div>
                <div className="w-full bg-purple-900/30 rounded-full h-3">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${progress}%` }}
                    transition={{ duration: 1, delay: index * 0.2 }}
                    className={`h-3 rounded-full bg-gradient-to-r ${getPriorityColor(goal.priority)}`}
                  />
                </div>
              </div>

              {/* Goal Stats */}
              <div className="grid grid-cols-3 gap-4">
                <div className="text-center">
                  <p className="text-2xl font-bold text-white">${(goal.target - goal.current).toLocaleString()}</p>
                  <p className="text-purple-200 text-sm">Remaining</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-white">{daysLeft}</p>
                  <p className="text-purple-200 text-sm">Days Left</p>
                </div>
                <div className="text-center">
                  <p className="text-2xl font-bold text-white">
                    ${Math.ceil((goal.target - goal.current) / Math.max(daysLeft, 1))}
                  </p>
                  <p className="text-purple-200 text-sm">Daily Need</p>
                </div>
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Add Goal CTA */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="glass-purple rounded-2xl p-8 text-center"
      >
        <div className="w-20 h-20 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center mx-auto mb-4">
          <Target className="w-10 h-10 text-white" />
        </div>
        <h3 className="text-xl font-bold text-white mb-2">Create a New Goal</h3>
        <p className="text-purple-200 mb-6">Set a financial target and let Xuzinha help you track it!</p>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-8 py-4 rounded-lg font-medium text-lg"
        >
          Add New Goal
        </motion.button>
      </motion.div>
    </div>
  );
};

export default GoalsWidget;
