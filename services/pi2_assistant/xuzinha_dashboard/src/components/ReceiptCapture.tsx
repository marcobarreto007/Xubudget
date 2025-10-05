import React, { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Camera, Upload, X, Check, Sparkles } from 'lucide-react';
import Webcam from 'react-webcam';
import { ollamaService } from '../services/ollamaService';

interface ReceiptCaptureProps {
  onClose: () => void;
  onCapture: (data: any) => void;
}

const ReceiptCapture: React.FC<ReceiptCaptureProps> = ({ onClose, onCapture }) => {
  const [mode, setMode] = useState<'camera' | 'upload' | 'processing' | 'preview'>('camera');
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [extractedData, setExtractedData] = useState<any>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const webcamRef = useRef<Webcam>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const capturePhoto = () => {
    if (webcamRef.current) {
      const imageSrc = webcamRef.current.getScreenshot();
      setCapturedImage(imageSrc);
      setMode('processing');
      processReceipt(imageSrc);
    }
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        const imageSrc = e.target?.result as string;
        setCapturedImage(imageSrc);
        setMode('processing');
        processReceipt(imageSrc);
      };
      reader.readAsDataURL(file);
    }
  };

  const processReceipt = async (imageSrc: string | null) => {
    if (!imageSrc) return;
    setIsProcessing(true);
    
    // Simulate OCR processing with Xuzinha's personality
    const processingSteps = [
      "Xuzinha is scanning your receipt...",
      "Extracting text and numbers...",
      "Identifying vendor and date...",
      "Categorizing the expense...",
      "Almost done!"
    ];

    for (let i = 0; i < processingSteps.length; i++) {
      await new Promise(resolve => setTimeout(resolve, 800));
    }

    try {
      // Try to use Ollama for categorization
      const isOllamaAvailable = await ollamaService.isAvailable();
      
      let category = "other";
      let confidence = 0.5;
      
      if (isOllamaAvailable) {
        // For now, use a mock description since we don't have real OCR
        const mockDescription = "Coffee & Pastry - Starbucks";
        const categorization = await ollamaService.categorizeExpense(mockDescription);
        category = categorization.category;
        confidence = categorization.confidence;
      }

      const extractedData = {
        description: "Coffee & Pastry",
        amount: 12.50,
        category: category,
        vendor: "Starbucks",
        date: new Date().toISOString().split('T')[0],
        image: imageSrc,
        confidence: confidence
      };

      setExtractedData(extractedData);
    } catch (error) {
      console.error('Error processing receipt:', error);
      // Fallback data
      const fallbackData = {
        description: "Coffee & Pastry",
        amount: 12.50,
        category: "food",
        vendor: "Starbucks",
        date: new Date().toISOString().split('T')[0],
        image: imageSrc,
        confidence: 0.5
      };
      setExtractedData(fallbackData);
    }

    setIsProcessing(false);
    setMode('preview');
  };

  const confirmData = () => {
    onCapture(extractedData);
    onClose();
  };

  const editData = (field: string, value: any) => {
    setExtractedData((prev: any) => ({
      ...prev,
      [field]: value
    }));
  };

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 receipt-overlay z-50 flex items-center justify-center p-4"
      >
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0.8, opacity: 0 }}
          className="glass-purple rounded-2xl p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto"
        >
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center">
                <Camera className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-xl font-bold text-white">Receipt Capture</h2>
                <p className="text-purple-200 text-sm">Xuzinha will extract the data for you</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-white/20 rounded-full transition-colors"
            >
              <X className="w-5 h-5 text-white" />
            </button>
          </div>

          {/* Content */}
          {mode === 'camera' && (
            <div className="space-y-6">
              <div className="text-center">
                <h3 className="text-lg font-semibold text-white mb-2">Take a Photo</h3>
                <p className="text-purple-200">Position the receipt clearly in the frame</p>
              </div>
              
              <div className="relative bg-black rounded-lg overflow-hidden">
                <Webcam
                  ref={webcamRef}
                  audio={false}
                  width="100%"
                  height={300}
                  className="w-full h-auto"
                />
                <div className="absolute inset-0 border-2 border-purple-400 rounded-lg pointer-events-none">
                  <div className="absolute top-2 left-2 w-6 h-6 border-l-2 border-t-2 border-purple-400 rounded-tl-lg"></div>
                  <div className="absolute top-2 right-2 w-6 h-6 border-r-2 border-t-2 border-purple-400 rounded-tr-lg"></div>
                  <div className="absolute bottom-2 left-2 w-6 h-6 border-l-2 border-b-2 border-purple-400 rounded-bl-lg"></div>
                  <div className="absolute bottom-2 right-2 w-6 h-6 border-r-2 border-b-2 border-purple-400 rounded-br-lg"></div>
                </div>
              </div>

              <div className="flex space-x-4">
                <button
                  onClick={capturePhoto}
                  className="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 text-white py-3 px-6 rounded-lg font-medium hover:from-purple-600 hover:to-pink-600 transition-all duration-300 flex items-center justify-center space-x-2"
                >
                  <Camera className="w-5 h-5" />
                  <span>Capture</span>
                </button>
                <button
                  onClick={() => setMode('upload')}
                  className="flex-1 glass text-white py-3 px-6 rounded-lg font-medium hover:bg-white/20 transition-all duration-300 flex items-center justify-center space-x-2"
                >
                  <Upload className="w-5 h-5" />
                  <span>Upload</span>
                </button>
              </div>
            </div>
          )}

          {mode === 'upload' && (
            <div className="space-y-6">
              <div className="text-center">
                <h3 className="text-lg font-semibold text-white mb-2">Upload Receipt</h3>
                <p className="text-purple-200">Select a receipt image from your device</p>
              </div>
              
              <div
                onClick={() => fileInputRef.current?.click()}
                className="border-2 border-dashed border-purple-400 rounded-lg p-8 text-center cursor-pointer hover:border-purple-300 transition-colors"
              >
                <Upload className="w-12 h-12 text-purple-400 mx-auto mb-4" />
                <p className="text-white font-medium mb-2">Click to select receipt image</p>
                <p className="text-purple-200 text-sm">PNG, JPG, or JPEG files</p>
              </div>
              
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileUpload}
                className="hidden"
              />

              <button
                onClick={() => setMode('camera')}
                className="w-full glass text-white py-3 px-6 rounded-lg font-medium hover:bg-white/20 transition-all duration-300"
              >
                Use Camera Instead
              </button>
            </div>
          )}

          {mode === 'processing' && (
            <div className="space-y-6 text-center">
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center mx-auto"
              >
                <Sparkles className="w-8 h-8 text-white" />
              </motion.div>
              
              <div>
                <h3 className="text-lg font-semibold text-white mb-2">Processing Receipt</h3>
                <p className="text-purple-200 mb-4">
                  {isProcessing ? "Xuzinha is analyzing your receipt..." : "Almost done!"}
                </p>
                
                <div className="w-full bg-purple-900/30 rounded-full h-2 mb-4">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: isProcessing ? "100%" : "100%" }}
                    transition={{ duration: 3 }}
                    className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full"
                  />
                </div>
              </div>
            </div>
          )}

          {mode === 'preview' && extractedData && (
            <div className="space-y-6">
              <div className="text-center">
                <h3 className="text-lg font-semibold text-white mb-2">Review Extracted Data</h3>
                <p className="text-purple-200">Xuzinha found this information - edit if needed</p>
              </div>

              {/* Receipt Image Preview */}
              <div className="flex justify-center">
                <img
                  src={capturedImage || ''}
                  alt="Receipt preview"
                  className="w-32 h-40 object-cover rounded-lg border-2 border-purple-400"
                />
              </div>

              {/* Extracted Data Form */}
              <div className="space-y-4">
                <div>
                  <label className="block text-white font-medium mb-2">Description</label>
                  <input
                    type="text"
                    value={extractedData.description}
                    onChange={(e) => editData('description', e.target.value)}
                    className="w-full bg-white/10 border border-purple-400 rounded-lg px-4 py-2 text-white placeholder-purple-200 focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-white font-medium mb-2">Amount</label>
                    <input
                      type="number"
                      step="0.01"
                      value={extractedData.amount}
                      onChange={(e) => editData('amount', parseFloat(e.target.value))}
                      className="w-full bg-white/10 border border-purple-400 rounded-lg px-4 py-2 text-white placeholder-purple-200 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    />
                  </div>
                  <div>
                    <label className="block text-white font-medium mb-2">Category</label>
                    <select
                      value={extractedData.category}
                      onChange={(e) => editData('category', e.target.value)}
                      className="w-full bg-white/10 border border-purple-400 rounded-lg px-4 py-2 text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                    >
                      <option value="food">Food</option>
                      <option value="transport">Transport</option>
                      <option value="health">Health</option>
                      <option value="housing">Housing</option>
                      <option value="utilities">Utilities</option>
                      <option value="shopping">Shopping</option>
                      <option value="entertainment">Entertainment</option>
                      <option value="education">Education</option>
                      <option value="savings">Savings</option>
                      <option value="other">Other</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-white font-medium mb-2">Vendor</label>
                  <input
                    type="text"
                    value={extractedData.vendor}
                    onChange={(e) => editData('vendor', e.target.value)}
                    className="w-full bg-white/10 border border-purple-400 rounded-lg px-4 py-2 text-white placeholder-purple-200 focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>

                <div className="flex items-center space-x-2 text-sm text-purple-200">
                  <Check className="w-4 h-4" />
                  <span>Confidence: {Math.round(extractedData.confidence * 100)}%</span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex space-x-4">
                <button
                  onClick={confirmData}
                  className="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 text-white py-3 px-6 rounded-lg font-medium hover:from-green-600 hover:to-emerald-600 transition-all duration-300 flex items-center justify-center space-x-2"
                >
                  <Check className="w-5 h-5" />
                  <span>Confirm & Add</span>
                </button>
                <button
                  onClick={() => setMode('camera')}
                  className="flex-1 glass text-white py-3 px-6 rounded-lg font-medium hover:bg-white/20 transition-all duration-300"
                >
                  Try Again
                </button>
              </div>
            </div>
          )}
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
};

export default ReceiptCapture;
