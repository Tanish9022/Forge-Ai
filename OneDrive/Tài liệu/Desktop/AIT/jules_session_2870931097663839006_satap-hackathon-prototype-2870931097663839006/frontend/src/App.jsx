import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Dashboard from './components/Dashboard';

function App() {
  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <header className="bg-military-dark border-b border-gray-700 p-4 shadow-lg">
        <div className="container mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-green-600 rounded-full flex items-center justify-center font-bold border border-green-400">S</div>
            <h1 className="text-xl font-bold tracking-wider text-green-500">SATAP <span className="text-gray-400 text-sm">| Threat Assessment Platform</span></h1>
          </div>
          <div className="text-xs text-gray-500 font-mono">
            SECURE LEDGER ACTIVE
          </div>
        </div>
      </header>
      
      <main className="container mx-auto p-4">
        <Dashboard />
      </main>
    </div>
  );
}

export default App;
