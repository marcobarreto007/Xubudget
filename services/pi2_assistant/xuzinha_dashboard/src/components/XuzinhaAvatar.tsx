import React from 'react';
import { motion } from 'framer-motion';
import { Sparkles, Heart, Brain, Zap } from 'lucide-react';

interface XuzinhaState {
  isActive: boolean;
  isProcessing: boolean;
  currentMessage: string;
  mood: 'happy' | 'focused' | 'processing' | 'sleeping';
}

interface XuzinhaAvatarProps {
  state: XuzinhaState;
  onClick: () => void;
}

const XuzinhaAvatar: React.FC<XuzinhaAvatarProps> = ({ state, onClick }) => {
  const getMoodIcon = () => {
    switch (state.mood) {
      case 'happy':
        return <Heart className="w-6 h-6 text-pink-400" />;
      case 'focused':
        return <Brain className="w-6 h-6 text-purple-400" />;
      case 'processing':
        return <Zap className="w-6 h-6 text-cyan-400" />;
      case 'sleeping':
        return <Sparkles className="w-6 h-6 text-yellow-400" />;
      default:
        return <Heart className="w-6 h-6 text-pink-400" />;
    }
  };

  const getMoodColor = () => {
    switch (state.mood) {
      case 'happy':
        return 'from-pink-400 to-purple-500';
      case 'focused':
        return 'from-purple-400 to-indigo-500';
      case 'processing':
        return 'from-cyan-400 to-blue-500';
      case 'sleeping':
        return 'from-yellow-400 to-orange-500';
      default:
        return 'from-pink-400 to-purple-500';
    }
  };

  return (
    <motion.div
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.95 }}
      onClick={onClick}
      className="relative cursor-pointer"
    >
      {/* Avatar Container */}
      <motion.div
        animate={{
          rotate: state.isProcessing ? [0, 5, -5, 0] : 0,
          scale: state.isActive ? [1, 1.05, 1] : 1,
        }}
        transition={{
          duration: state.isProcessing ? 0.5 : 2,
          repeat: state.isProcessing ? Infinity : Infinity,
          repeatDelay: state.isProcessing ? 0 : 3,
        }}
        className={`w-16 h-16 rounded-full bg-gradient-to-r ${getMoodColor()} p-1 shadow-lg`}
      >
        <div className="w-full h-full rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
          {getMoodIcon()}
        </div>
      </motion.div>

      {/* Status Indicator */}
      <motion.div
        animate={{
          scale: state.isActive ? [1, 1.2, 1] : 0,
          opacity: state.isActive ? [0.7, 1, 0.7] : 0,
        }}
        transition={{
          duration: 1.5,
          repeat: Infinity,
        }}
        className={`absolute -top-1 -right-1 w-4 h-4 rounded-full ${
          state.isProcessing ? 'bg-cyan-400' : 'bg-green-400'
        } shadow-lg`}
      />

      {/* Processing Ring */}
      {state.isProcessing && (
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
          className="absolute inset-0 rounded-full border-2 border-transparent border-t-cyan-400 border-r-pink-400"
        />
      )}

      {/* Floating Sparkles */}
      {state.mood === 'happy' && (
        <>
          {[...Array(3)].map((_, i) => (
            <motion.div
              key={i}
              animate={{
                y: [0, -20, 0],
                x: [0, Math.random() * 20 - 10, 0],
                opacity: [0, 1, 0],
                scale: [0, 1, 0],
              }}
              transition={{
                duration: 2,
                delay: i * 0.3,
                repeat: Infinity,
                repeatDelay: 3,
              }}
              className="absolute -top-2 -right-2 w-2 h-2 bg-yellow-400 rounded-full"
            />
          ))}
        </>
      )}

      {/* Glow Effect */}
      <motion.div
        animate={{
          opacity: state.isActive ? [0.3, 0.6, 0.3] : 0,
        }}
        transition={{
          duration: 2,
          repeat: Infinity,
        }}
        className={`absolute inset-0 rounded-full bg-gradient-to-r ${getMoodColor()} blur-md -z-10`}
      />
    </motion.div>
  );
};

export default XuzinhaAvatar;
