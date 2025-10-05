import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Mic, MicOff, Camera, BarChart3, Target, Wallet, X } from 'lucide-react';

interface FloatingCommandBarProps {
  onCommand: (command: string) => void;
}

const FloatingCommandBar: React.FC<FloatingCommandBarProps> = ({ onCommand }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [isListening, setIsListening] = useState(false);

  const quickCommands = [
    { id: 'scan_receipt', label: 'Scan Receipt', icon: Camera, color: 'from-purple-500 to-pink-500' },
    { id: 'show_budget', label: 'Show Budget', icon: BarChart3, color: 'from-blue-500 to-cyan-500' },
    { id: 'show_goals', label: 'Show Goals', icon: Target, color: 'from-green-500 to-emerald-500' },
    { id: 'show_analytics', label: 'Show Analytics', icon: Wallet, color: 'from-orange-500 to-red-500' }
  ];

  const handleVoiceCommand = () => {
    setIsListening(true);
    
    // Simulate voice recognition
    setTimeout(() => {
      setIsListening(false);
      // In a real app, this would process the voice input
      const randomCommand = quickCommands[Math.floor(Math.random() * quickCommands.length)];
      onCommand(randomCommand.id);
    }, 2000);
  };

  return (
    <>
      {/* Floating Action Button */}
      <motion.button
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        onClick={() => setIsOpen(!isOpen)}
        className="fixed bottom-24 right-6 z-40 w-14 h-14 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center shadow-lg"
      >
        <motion.div
          animate={{ rotate: isOpen ? 45 : 0 }}
          transition={{ duration: 0.3 }}
        >
          {isOpen ? <X className="w-6 h-6 text-white" /> : <Mic className="w-6 h-6 text-white" />}
        </motion.div>
      </motion.button>

      {/* Command Panel */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.8, y: 20 }}
            className="fixed bottom-32 right-6 z-40 glass-purple rounded-2xl p-6 min-w-80"
          >
            <div className="text-center mb-6">
              <h3 className="text-lg font-bold text-white mb-2">Xuzinha Commands</h3>
              <p className="text-purple-200 text-sm">Choose an action or use voice</p>
            </div>

            {/* Voice Command Button */}
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={handleVoiceCommand}
              disabled={isListening}
              className={`w-full mb-4 py-3 px-6 rounded-lg font-medium flex items-center justify-center space-x-2 ${
                isListening
                  ? 'bg-gradient-to-r from-cyan-500 to-blue-500 text-white'
                  : 'bg-gradient-to-r from-purple-500 to-pink-500 text-white hover:from-purple-600 hover:to-pink-600'
              }`}
            >
              {isListening ? (
                <>
                  <motion.div
                    animate={{ rotate: 360 }}
                    transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                  >
                    <MicOff className="w-5 h-5" />
                  </motion.div>
                  <span>Listening...</span>
                </>
              ) : (
                <>
                  <Mic className="w-5 h-5" />
                  <span>Voice Command</span>
                </>
              )}
            </motion.button>

            {/* Quick Commands */}
            <div className="space-y-3">
              {quickCommands.map((command) => (
                <motion.button
                  key={command.id}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => {
                    onCommand(command.id);
                    setIsOpen(false);
                  }}
                  className={`w-full bg-gradient-to-r ${command.color} text-white py-3 px-4 rounded-lg font-medium flex items-center space-x-3`}
                >
                  <command.icon className="w-5 h-5" />
                  <span>{command.label}</span>
                </motion.button>
              ))}
            </div>

            {/* Sample Voice Commands */}
            <div className="mt-6 pt-4 border-t border-purple-400/20">
              <p className="text-purple-200 text-sm mb-3">Try saying:</p>
              <div className="space-y-2">
                {[
                  "Scan this receipt",
                  "Show my budget",
                  "What are my goals?",
                  "Show analytics"
                ].map((phrase, index) => (
                  <motion.div
                    key={phrase}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="text-purple-300 text-sm bg-white/5 rounded-lg px-3 py-2"
                  >
                    "{phrase}"
                  </motion.div>
                ))}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Backdrop */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsOpen(false)}
            className="fixed inset-0 bg-black/20 backdrop-blur-sm z-30"
          />
        )}
      </AnimatePresence>
    </>
  );
};

export default FloatingCommandBar;
