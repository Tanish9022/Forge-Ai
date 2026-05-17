import React, { useEffect, useState } from 'react';
import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000/api';

const Ledger = ({ updateTrigger }) => {
    const [chain, setChain] = useState([]);
    const [isValid, setIsValid] = useState(true);

    const fetchChain = async () => {
        try {
            const response = await axios.get(`${API_BASE_URL}/chain_status`);
            setChain(response.data.chain.reverse()); // Show newest first
            setIsValid(response.data.is_valid);
        } catch (error) {
            console.error("Error fetching ledger:", error);
        }
    };

    useEffect(() => {
        fetchChain();
    }, [updateTrigger]);

    return (
        <div>
            <div className="flex justify-between items-center mb-4 border-b border-gray-700 pb-2">
                <h2 className="text-lg font-semibold text-gray-300">Immutable Ledger</h2>
                <div className="flex items-center space-x-2">
                    <span className="text-xs text-gray-500">Integrity Status:</span>
                    {isValid ? (
                        <span className="text-xs bg-green-900 text-green-400 px-2 py-1 rounded border border-green-700">SECURE</span>
                    ) : (
                        <span className="text-xs bg-red-900 text-red-400 px-2 py-1 rounded border border-red-700 animate-pulse">COMPROMISED</span>
                    )}
                </div>
            </div>

            <div className="overflow-x-auto">
                <table className="min-w-full text-left text-sm text-gray-400">
                    <thead className="bg-gray-900 text-gray-500 font-mono text-xs uppercase">
                        <tr>
                            <th className="px-4 py-2">Index</th>
                            <th className="px-4 py-2">Timestamp</th>
                            <th className="px-4 py-2">Action</th>
                            <th className="px-4 py-2">Prev. Hash</th>
                            <th className="px-4 py-2">Block Hash</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-700">
                        {chain.map((block) => (
                            <tr key={block.index} className="hover:bg-gray-700/50 transition-colors">
                                <td className="px-4 py-2 font-mono text-white">#{block.index}</td>
                                <td className="px-4 py-2">{new Date(block.timestamp * 1000).toLocaleTimeString()}</td>
                                <td className="px-4 py-2">
                                    <span className={`px-2 py-0.5 rounded text-xs border ${
                                        block.data.action === 'Escalate' ? 'bg-red-900/30 border-red-800 text-red-400' :
                                        block.data.action === 'Dismiss' ? 'bg-gray-700 border-gray-600 text-gray-300' :
                                        'bg-blue-900/30 border-blue-800 text-blue-400'
                                    }`}>
                                        {block.data.action || 'INIT'}
                                    </span>
                                </td>
                                <td className="px-4 py-2 font-mono text-xs truncate max-w-[100px]" title={block.previous_hash}>
                                    {block.previous_hash.substring(0, 8)}...
                                </td>
                                <td className="px-4 py-2 font-mono text-xs text-green-500 truncate max-w-[100px]" title={block.hash}>
                                    {block.hash.substring(0, 8)}...
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Ledger;
