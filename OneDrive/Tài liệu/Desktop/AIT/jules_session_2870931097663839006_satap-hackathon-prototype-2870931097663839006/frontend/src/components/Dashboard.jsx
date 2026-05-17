import React, { useState, useEffect } from 'react';
import axios from 'axios';
import MapComponent from './MapComponent';
import Ledger from './Ledger';

const API_BASE_URL = 'http://localhost:5000/api';

const Dashboard = () => {
  const [inputText, setInputText] = useState('');
  const [analysisResult, setAnalysisResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [logging, setLogging] = useState(false);
  const [ledgerUpdateTrigger, setLedgerUpdateTrigger] = useState(0);

  const handleAnalyze = async () => {
    if (!inputText.trim()) return;
    setLoading(true);
    setAnalysisResult(null);
    try {
      const response = await axios.post(`${API_BASE_URL}/assess_threat`, { text: inputText });
      setAnalysisResult(response.data);
    } catch (error) {
      console.error("Error analyzing text:", error);
      alert("Analysis failed. See console for details.");
    } finally {
      setLoading(false);
    }
  };

  const handleLogDecision = async (action) => {
    if (!analysisResult) return;
    setLogging(true);
    try {
      const payload = {
        report_id: `RPT-${Date.now()}`, // Simple ID generation
        text: inputText.substring(0, 50) + "...",
        ai_score: analysisResult.threat_score,
        analyst_action: action,
        analyst_id: "ANALYST-001" // Simulated ID
      };
      
      await axios.post(`${API_BASE_URL}/log_decision`, payload);
      setLedgerUpdateTrigger(prev => prev + 1); // Refresh ledger
      alert(`Decision '${action}' Logged to Blockchain.`);
    } catch (error) {
      console.error("Error logging decision:", error);
      alert("Failed to log decision.");
    } finally {
      setLogging(false);
    }
  };

  const getThreatColor = (score) => {
    if (score < 0.3) return 'text-green-500';
    if (score < 0.7) return 'text-yellow-500';
    return 'text-red-500';
  };

  const getThreatBg = (score) => {
    if (score < 0.3) return 'bg-green-900/20 border-green-700';
    if (score < 0.7) return 'bg-yellow-900/20 border-yellow-700';
    return 'bg-red-900/20 border-red-700';
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Left Column: Input & Analysis */}
      <div className="lg:col-span-1 space-y-6">
        {/* Input Module */}
        <div className="bg-gray-800 rounded-lg p-5 border border-gray-700 shadow-lg">
          <h2 className="text-lg font-semibold mb-3 text-gray-300 border-b border-gray-700 pb-2">1. Intel Input</h2>
          <textarea
            className="w-full h-40 bg-gray-900 text-gray-200 p-3 rounded border border-gray-600 focus:border-green-500 focus:ring-1 focus:ring-green-500 outline-none font-mono text-sm"
            placeholder="Paste raw intelligence report here..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
          ></textarea>
          <button
            onClick={handleAnalyze}
            disabled={loading || !inputText}
            className={`w-full mt-3 py-2 px-4 rounded font-bold tracking-wide transition-colors ${
              loading ? 'bg-gray-600 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700 text-white'
            }`}
          >
            {loading ? 'ANALYZING...' : 'ASSESS THREAT'}
          </button>
        </div>

        {/* Results Module */}
        {analysisResult && (
          <div className={`rounded-lg p-5 border shadow-lg ${getThreatBg(analysisResult.threat_score)}`}>
            <h2 className="text-lg font-semibold mb-3 text-gray-300 border-b border-gray-700 pb-2">2. AI Assessment</h2>
            
            <div className="flex justify-between items-center mb-4">
              <span className="text-gray-400">Threat Score:</span>
              <span className={`text-3xl font-bold ${getThreatColor(analysisResult.threat_score)}`}>
                {(analysisResult.threat_score * 100).toFixed(0)}/100
              </span>
            </div>
            
            <div className="mb-4">
               <span className="text-xs text-gray-500 uppercase">Confidence:</span>
               <div className="w-full bg-gray-700 h-2 rounded-full mt-1">
                 <div 
                    className="bg-blue-500 h-2 rounded-full" 
                    style={{ width: `${analysisResult.confidence_score * 100}%` }}
                 ></div>
               </div>
            </div>

            <div className="space-y-2 mb-6">
                <span className="text-xs text-gray-500 uppercase">Extracted Entities:</span>
                <div className="flex flex-wrap gap-2">
                    {analysisResult.entities && analysisResult.entities.map((ent, idx) => (
                        <span key={idx} className="px-2 py-1 bg-black/40 rounded text-xs border border-gray-600 flex items-center">
                            <span className="font-bold text-gray-400 mr-1">{ent.type}:</span> {ent.value}
                        </span>
                    ))}
                </div>
            </div>

            {/* Decision Module */}
            <div className="border-t border-gray-700 pt-4">
                <h3 className="text-sm text-gray-400 mb-2 uppercase font-bold">Analyst Decision</h3>
                <div className="grid grid-cols-2 gap-3">
                    <button 
                        onClick={() => handleLogDecision('Dismiss')}
                        disabled={logging}
                        className="bg-gray-700 hover:bg-gray-600 text-white py-2 rounded text-sm font-semibold"
                    >
                        DISMISS
                    </button>
                    <button 
                        onClick={() => handleLogDecision('Escalate')}
                        disabled={logging}
                        className="bg-red-700 hover:bg-red-600 text-white py-2 rounded text-sm font-semibold"
                    >
                        ESCALATE
                    </button>
                </div>
            </div>
          </div>
        )}
      </div>

      {/* Middle/Right Column: Map & Ledger */}
      <div className="lg:col-span-2 space-y-6">
        {/* Map Module */}
        <div className="bg-gray-800 rounded-lg border border-gray-700 shadow-lg overflow-hidden h-96 flex flex-col">
            <div className="bg-gray-800 p-3 border-b border-gray-700 flex justify-between items-center">
                <h2 className="text-lg font-semibold text-gray-300">Geo-Spatial Viz</h2>
                <span className="text-xs text-green-500 font-mono animate-pulse">● LIVE FEED</span>
            </div>
            <div className="flex-1 relative z-0">
                <MapComponent analysisResult={analysisResult} />
            </div>
        </div>

        {/* Ledger Module */}
        <div className="bg-gray-800 rounded-lg p-5 border border-gray-700 shadow-lg">
             <Ledger updateTrigger={ledgerUpdateTrigger} />
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
