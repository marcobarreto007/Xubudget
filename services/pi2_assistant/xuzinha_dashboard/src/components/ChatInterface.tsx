import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Send, X, Camera, BarChart3, Target, Wallet, Bot } from 'lucide-react';
import { backendSyncService } from '../services/backendSync';
import { sendToAgent, fetchTotals } from '../services/agent';

interface XuzinhaState {
  isActive: boolean;
  isProcessing: boolean;
  currentMessage: string;
  mood: 'happy' | 'focused' | 'processing' | 'sleeping';
}

interface Expense {
  id: string;
  amount: number;
  category: string;
  description: string;
  date: string;
  receiptImage?: string;
  vendor?: string;
}

interface ChatInterfaceProps {
  onClose: () => void;
  xuzinhaState: XuzinhaState;
  onCommand: (command: string) => void;
  expenses: Expense[];
  onExpensesChange: (expenses: Expense[]) => void;
  monthlyIncome: number;
  weeklyIncome: number;
  governmentAssistance: number;
  totalWeeklyIncome: number;
  budgets: { [key: string]: number };
  categoryRemaining: { category: string; budget: number; spent: number; remaining: number; percentage: number }[];
  totalSpent: number;
  remainingBudget: number;
}

interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: Date;
  type: 'text' | 'expense' | 'income' | 'analysis';
}

const ChatInterface: React.FC<ChatInterfaceProps> = ({ 
  onClose, 
  xuzinhaState, 
  onCommand, 
  expenses, 
  onExpensesChange, 
  monthlyIncome, 
  weeklyIncome, 
  governmentAssistance, 
  totalWeeklyIncome, 
  budgets, 
  categoryRemaining, 
  totalSpent, 
  remainingBudget 
}) => {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: '1',
      text: "🤖 Olá! Eu sou a Xuzinha, sua assistente financeira! Como posso ajudar você hoje?",
      isUser: false,
      timestamp: new Date(),
      type: 'text'
    }
  ]);
  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  
  // Draggable and resizable state
  const [position, setPosition] = useState({ x: 50, y: 50 });
  const [size, setSize] = useState({ width: 400, height: 600 });
  const [isDragging, setIsDragging] = useState(false);
  const [isResizing, setIsResizing] = useState(false);
  const [isMinimized, setIsMinimized] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [resizeStart, setResizeStart] = useState({ x: 0, y: 0, width: 0, height: 0 });
  const chatRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  // Xuzinha Avatar Component - Real Image
  const XuzinhaAvatar = ({ size = 40, className = "" }) => (
    <div className={`relative ${className}`} style={{ width: size, height: size }}>
      {/* Outer Glow Ring */}
      <div className="absolute inset-0 rounded-full bg-gradient-to-r from-cyan-400 via-purple-400 to-pink-400 p-0.5">
        <div className="w-full h-full rounded-full bg-black/90 flex items-center justify-center overflow-hidden">
          {/* Real Image Avatar */}
          <img 
            src="/images/xuzinha/xuzinha_avatar.png" 
            alt="Xuzinha Avatar"
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
              <div className="absolute -top-1 left-0 right-0 h-3 bg-gradient-to-b from-gray-800 to-gray-900 rounded-t-full">
                {/* Circuitry Lines in Hair */}
                <div className="absolute top-1 left-1 right-1 h-px bg-cyan-400"></div>
                <div className="absolute top-1.5 left-2 right-2 h-px bg-purple-400"></div>
                <div className="absolute top-2 left-1 right-1 h-px bg-pink-400"></div>
              </div>
              
              {/* Eyes */}
              <div className="absolute top-2 left-1.5 w-1 h-1 bg-cyan-400 rounded-full"></div>
              <div className="absolute top-2 right-1.5 w-1 h-1 bg-cyan-400 rounded-full"></div>
              
              {/* Glasses Frame */}
              <div className="absolute top-1.5 left-0.5 right-0.5 h-1.5 border-2 border-cyan-400 rounded-full"></div>
              <div className="absolute top-1.5 left-1/2 w-px h-1.5 bg-cyan-400"></div>
              
              {/* Nose */}
              <div className="absolute top-3 left-1/2 w-0.5 h-0.5 bg-gray-300 rounded-full transform -translate-x-1/2"></div>
              
              {/* Smile */}
              <div className="absolute bottom-1.5 left-1 right-1 h-0.5 border-b-2 border-cyan-400 rounded-full"></div>
              
              {/* Circuitry on Face */}
              <div className="absolute top-2.5 left-0 right-0 h-px bg-cyan-400/60"></div>
              <div className="absolute bottom-2 left-0 right-0 h-px bg-purple-400/60"></div>
              
              {/* Metallic Plates */}
              <div className="absolute top-1 left-1 w-1 h-1 bg-gray-400 rounded-sm opacity-60"></div>
              <div className="absolute top-1 right-1 w-1 h-1 bg-gray-400 rounded-sm opacity-60"></div>
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
  );

  // Drag and resize handlers
  const handleMouseDown = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
    setDragStart({
      x: e.clientX - position.x,
      y: e.clientY - position.y
    });
  };

  const handleResizeMouseDown = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsResizing(true);
    setResizeStart({
      x: e.clientX,
      y: e.clientY,
      width: size.width,
      height: size.height
    });
  };

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (isDragging) {
        setPosition({
          x: e.clientX - dragStart.x,
          y: e.clientY - dragStart.y
        });
      }
      if (isResizing) {
        const newWidth = Math.max(280, resizeStart.width + (e.clientX - resizeStart.x));
        const newHeight = Math.max(350, resizeStart.height + (e.clientY - resizeStart.y));
        setSize({ width: newWidth, height: newHeight });
      }
    };

    const handleMouseUp = () => {
      setIsDragging(false);
      setIsResizing(false);
    };

    if (isDragging || isResizing) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
    }

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, isResizing, dragStart, resizeStart]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Function to clamp text length
  const clampText = (text: string, maxChars: number = 120): string => {
    return text.length > maxChars ? text.slice(0, maxChars).trim() + '…' : text;
  };

  // Function to detect language
  const detectLanguage = (text: string): 'pt' | 'en' => {
    const portugueseWords = ['gastei', 'ganhei', 'orçamento', 'ajuda', 'despesa', 'receita', 'dinheiro', 'poupança', 'investimento', 'casa', 'comida', 'transporte', 'saúde', 'lazer', 'educação', 'como', 'quando', 'onde', 'porque', 'quanto', 'qual', 'que', 'não', 'sim', 'obrigado', 'por favor'];
    const englishWords = ['spent', 'earned', 'budget', 'help', 'expense', 'income', 'money', 'savings', 'investment', 'house', 'food', 'transport', 'health', 'entertainment', 'education', 'how', 'when', 'where', 'why', 'how much', 'what', 'no', 'yes', 'thank you', 'please'];
    
    const textLower = text.toLowerCase();
    const ptCount = portugueseWords.filter(word => textLower.includes(word)).length;
    const enCount = englishWords.filter(word => textLower.includes(word)).length;
    
    return ptCount >= enCount ? 'pt' : 'en';
  };

  const handleSendMessage = async () => {
    if (!inputText.trim()) return;

    console.log('Sending message:', inputText);

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      text: inputText,
      isUser: true,
      timestamp: new Date(),
      type: 'text'
    };

    setMessages(prev => [...prev, userMessage]);
    const currentInput = inputText;
    setInputText('');
    setIsTyping(true);

    // Detect language
    const detectedLanguage = detectLanguage(currentInput);
    const isPortuguese = detectedLanguage === 'pt';

    try {
      // Send message to new agent
      const { text, tools } = await sendToAgent(currentInput);
      
      // Check if modification tools were used and refresh data
      if (tools.some(t => ['db.update_expense','db.set_category','db.reset'].includes(t))) {
        try {
          const data = await fetchTotals();
          console.log('Budget refreshed after modification:', data);
          
          // Force UI refresh by calling onCommand with refresh signal
          onCommand('SYNC:REFRESH_BUDGET');
          
          // Update expenses from totals if available
          if (data && typeof data === 'object') {
            const totals = data.totals || data;
            if (totals && typeof totals === 'object') {
              const expenses = Object.entries(totals).map(([category, amount]) => ({
                id: `expense-${category}`,
                category,
                amount: Number(amount),
                description: `Gasto em ${category}`,
                date: new Date().toISOString()
              }));
              onExpensesChange(expenses);
            }
          }
        } catch (error) {
          console.error('Failed to refresh budget:', error);
          // Force refresh anyway
          onCommand('SYNC:REFRESH_BUDGET');
        }
      }

      const xuzinhaMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        text: clampText(text),
        isUser: false,
        timestamp: new Date(),
        type: 'text'
      };

      setMessages(prev => [...prev, xuzinhaMessage]);
      setIsTyping(false);
    } catch (error) {
      console.error('Backend sync error:', error);
      
      // Fallback to simulated response - Language detected
      let response = "";
      
      if (currentInput.toLowerCase().includes('gastei') || currentInput.toLowerCase().includes('gastou')) {
        response = isPortuguese ? 
          "💰 **DESPESA REGISTRADA!** 💰\n\nCapturei sua despesa! Vou adicionar ao seu rastreador de orçamento.\n\n*Processando dados financeiros...*" :
          "💰 **EXPENSE RECORDED!** 💰\n\nI've captured your expense! Let me add it to your budget tracker.\n\n*Processing financial data...*";
      } else if (currentInput.toLowerCase().includes('ganhei') || currentInput.toLowerCase().includes('receita')) {
        response = isPortuguese ?
          "💵 **RECEITA REGISTRADA!** 💵\n\nÓtimo! Adicionei sua receita ao sistema.\n\n*Atualizando cálculos do orçamento...*" :
          "💵 **INCOME RECORDED!** 💵\n\nGreat! I've added your income to the system.\n\n*Updating budget calculations...*";
      } else if (currentInput.toLowerCase().includes('orçamento') || currentInput.toLowerCase().includes('budget')) {
        response = isPortuguese ?
          "📊 **VISÃO GERAL DO ORÇAMENTO** 📊\n\nAqui está seu status financeiro atual:\n• Receita Total: $4,000\n• Total Gasto: $20\n• Restante: $3,980\n• Meta de Poupança: 20%" :
          "📊 **BUDGET OVERVIEW** 📊\n\nHere's your current financial status:\n• Total Income: $4,000\n• Total Spent: $20\n• Remaining: $3,980\n• Savings Goal: 20%";
      } else if (currentInput.toLowerCase().includes('ajuda') || currentInput.toLowerCase().includes('help')) {
        response = isPortuguese ?
          "🤖 **ASSISTENTE IA XUZINHA** 🤖\n\nEstou aqui para ajudar com:\n• 💰 Rastreamento de despesas\n• 💵 Gestão de receitas\n• 📊 Análise de orçamento\n• 🎯 Metas financeiras\n\nApenas me diga o que você precisa!" :
          "🤖 **XUZINHA AI ASSISTANT** 🤖\n\nI'm here to help with:\n• 💰 Expense tracking\n• 💵 Income management\n• 📊 Budget analysis\n• 🎯 Financial goals\n\nJust tell me what you need!";
      } else {
        response = isPortuguese ?
          "🤖 **RESPOSTA XUZINHA** 🤖\n\nEntendo! Deixe-me ajudar com isso.\n\n*Processando sua solicitação...*" :
          "🤖 **XUZINHA RESPONSE** 🤖\n\nI understand! Let me help you with that.\n\n*Processing your request...*";
      }

      const xuzinhaMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        text: response,
        isUser: false,
        timestamp: new Date(),
        type: 'text'
      };

      setMessages(prev => [...prev, xuzinhaMessage]);
      setIsTyping(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  return (
    <AnimatePresence>
      <motion.div
        ref={chatRef}
        initial={{ opacity: 0, x: 300, scale: 0.8 }}
        animate={{ 
          opacity: 1, 
          x: position.x, 
          y: position.y, 
          scale: 1,
          width: size.width,
          height: isMinimized ? 80 : size.height
        }}
        exit={{ opacity: 0, x: 300, scale: 0.8 }}
        className="fixed z-[9999] flex flex-col select-none"
        style={{ 
          zIndex: 9999,
          left: position.x,
          top: position.y,
          width: size.width,
          height: isMinimized ? 80 : size.height
        }}
      >
        {/* Cyberpunk Glass Container - Frosted Glass */}
        <div className="relative h-full w-full overflow-hidden">
          {/* Frosted Glass Background */}
          <div className="absolute inset-0 bg-gradient-to-br from-purple-900/30 via-blue-900/30 to-cyan-900/30 backdrop-blur-md">
            {/* Subtle Grid Pattern - No Animation */}
            <div className="absolute inset-0 opacity-10">
              <div className="grid grid-cols-8 grid-rows-8 h-full w-full">
                {Array.from({ length: 64 }).map((_, i) => (
                  <div
                    key={i}
                    className="border border-cyan-400/20"
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Main Content Container */}
          <div className="relative z-10 h-full flex flex-col">
            {/* Neon Border Effect */}
            <div className="absolute inset-0 bg-gradient-to-r from-cyan-400/10 via-purple-400/10 to-pink-400/10 rounded-lg"></div>
            <div className="absolute inset-0 border-2 border-transparent bg-gradient-to-r from-cyan-400 via-purple-400 to-pink-400 rounded-lg p-[2px]">
              <div className="h-full w-full bg-black/80 rounded-lg"></div>
            </div>
            
            {/* Header */}
            <div 
              className="header-area drag-handle relative p-6 border-b border-cyan-400/30 cursor-move"
              onMouseDown={handleMouseDown}
            >
              {/* Animated Header Background */}
              <div className="absolute inset-0 bg-gradient-to-r from-cyan-400/5 via-purple-400/5 to-pink-400/5"></div>
              
              {/* Drag Indicator */}
              <div className="absolute top-2 left-1/2 transform -translate-x-1/2 flex space-x-1">
                <div className="w-1 h-1 bg-cyan-400/50 rounded-full"></div>
                <div className="w-1 h-1 bg-cyan-400/50 rounded-full"></div>
                <div className="w-1 h-1 bg-cyan-400/50 rounded-full"></div>
              </div>
              
              <div className="relative flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  {/* Xuzinha Avatar - Stable */}
                  <div className="relative">
                    <XuzinhaAvatar size={48} />
                  </div>
                  
                  <div>
                    <h2 className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 via-purple-400 to-pink-400 font-bold text-xl">
                      XUBUDGET.AI
                    </h2>
                    <p className="text-cyan-300 text-sm">Financial AI Assistant</p>
                  </div>
                </div>
                
                {/* Minimize Button */}
                <motion.button
                  onClick={() => setIsMinimized(!isMinimized)}
                  className="relative p-2 text-yellow-400 hover:text-yellow-300 transition-colors group mr-2"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.9 }}
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-yellow-400/20 to-orange-400/20 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity"></div>
                  {isMinimized ? (
                    <svg className="w-6 h-6 relative z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
                    </svg>
                  ) : (
                    <svg className="w-6 h-6 relative z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4" />
                    </svg>
                  )}
                </motion.button>

                {/* Close Button */}
                <motion.button
                  onClick={onClose}
                  className="relative p-2 text-cyan-300 hover:text-white transition-colors group"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.9 }}
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-cyan-400/20 to-purple-400/20 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity"></div>
                  <X className="w-6 h-6 relative z-10" />
                </motion.button>
              </div>
            </div>

            {/* Messages */}
            {!isMinimized && (
              <div className="relative flex-1 overflow-y-auto p-6 space-y-4">
                {/* Animated Background Pattern */}
                <div className="absolute inset-0 opacity-5">
                  <div className="grid grid-cols-8 grid-rows-8 h-full w-full">
                    {Array.from({ length: 64 }).map((_, i) => (
                      <motion.div
                        key={i}
                        className="border border-cyan-400/10"
                        animate={{
                          opacity: [0.1, 0.3, 0.1],
                          scale: [1, 1.05, 1]
                        }}
                        transition={{
                          duration: 2,
                          delay: i * 0.01,
                          repeat: Infinity,
                          repeatType: "reverse"
                        }}
                      />
                    ))}
                  </div>
                </div>

                {/* Messages List */}
                <div className="relative space-y-4">
                  {messages.map((message) => (
                    <div
                      key={message.id}
                      className={`flex ${message.isUser ? 'justify-end' : 'justify-start'}`}
                    >
                      <div className={`max-w-xs ${message.isUser ? 'order-2' : 'order-1'}`}>
                        <div className={`glass px-4 py-3 rounded-2xl ${
                          message.isUser 
                            ? 'bg-gradient-to-r from-cyan-500/20 to-purple-500/20 border border-cyan-400/30' 
                            : 'bg-gradient-to-r from-purple-500/20 to-pink-500/20 border border-purple-400/30'
                        }`}>
                          <p className="text-white text-sm whitespace-pre-wrap">{message.text}</p>
                          <p className="text-cyan-300/70 text-xs mt-2">
                            {message.timestamp.toLocaleTimeString()}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}

                  {/* Typing Indicator */}
                  {isTyping && (
                    <div className="flex justify-start">
                      <div className="glass px-4 py-3 rounded-2xl">
                        <div className="flex items-center space-x-2">
                          <div className="w-2 h-2 bg-cyan-400 rounded-full animate-pulse"></div>
                          <span className="text-white text-sm">Xuzinha is typing...</span>
                        </div>
                      </div>
                    </div>
                  )}

                  <div ref={messagesEndRef} />
                </div>
              </div>
            )}

            {/* Input Area */}
            {!isMinimized && (
              <div className="relative p-6 border-t border-cyan-400/30">
                {/* Animated Input Background */}
                <div className="absolute inset-0 bg-gradient-to-r from-cyan-400/5 via-purple-400/5 to-pink-400/5"></div>
                
                <div className="relative flex space-x-3">
                  {/* Cyberpunk Input */}
                  <div className="relative flex-1">
                    <div className="absolute inset-0 bg-gradient-to-r from-cyan-400/20 to-purple-400/20 rounded-lg blur-sm"></div>
                    <input
                      type="text"
                      value={inputText}
                      onChange={(e) => setInputText(e.target.value)}
                      onKeyPress={handleKeyPress}
                      placeholder="> ENTER COMMAND..."
                      className="relative w-full bg-black/40 border border-cyan-400/50 rounded-lg px-4 py-3 text-cyan-100 placeholder-cyan-400/70 focus:outline-none focus:ring-2 focus:ring-cyan-400/50 focus:border-cyan-400 font-mono backdrop-blur-sm"
                    />
                    
                    {/* Static Cursor */}
                    <div className="absolute right-3 top-1/2 transform -translate-y-1/2 w-0.5 h-6 bg-cyan-400/50" />
                  </div>
                  
                  {/* Cyberpunk Send Button - Stable */}
                  <button
                    onClick={handleSendMessage}
                    disabled={!inputText.trim()}
                    className="relative group"
                  >
                    {/* Button Glow */}
                    <div className="absolute inset-0 bg-gradient-to-r from-cyan-400 to-purple-400 rounded-lg blur-sm opacity-0 group-hover:opacity-100 transition-opacity"></div>
                    
                    {/* Button Core */}
                    <div className={`relative bg-gradient-to-r from-cyan-500 to-purple-500 text-white p-3 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed border border-cyan-400/50 ${
                      inputText.trim() ? 'shadow-lg shadow-cyan-400/25' : ''
                    }`}>
                      <Send className="w-5 h-5" />
                    </div>
                  </button>
                </div>
              </div>
            )}
          </div>
          
          {/* Resize Handle */}
          {!isMinimized && (
            <div
              className="absolute bottom-0 right-0 w-4 h-4 cursor-se-resize opacity-0 hover:opacity-100 transition-opacity"
              onMouseDown={handleResizeMouseDown}
              style={{
                background: 'linear-gradient(45deg, transparent 30%, cyan 30%, cyan 70%, transparent 70%)',
                clipPath: 'polygon(100% 0%, 0% 100%, 100% 100%)'
              }}
            >
              <div className="absolute bottom-0 right-0 w-2 h-2 bg-cyan-400/50 rounded-full"></div>
            </div>
          )}
        </div>
      </motion.div>
    </AnimatePresence>
  );
};

export default ChatInterface;