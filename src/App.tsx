import React, { useEffect } from 'react';
import { ErrorBoundary } from './components/ErrorBoundary';
import { AppContent } from './components/AppContent';
import { testConnection, testRPCFunctions } from './lib/supabase-test';

function App() {
  useEffect(() => {
    // Run all Supabase tests on mount
    async function runTests() {
      console.group('Supabase Connection Tests');
      
      // Test basic table access
      const connectionSuccess = await testConnection();
      console.log('Basic connection test:', connectionSuccess ? 'Passed' : 'Failed');
      
      // Test RPC functions
      const rpcSuccess = await testRPCFunctions();
      console.log('RPC functions test:', rpcSuccess ? 'Passed' : 'Failed');
      
      console.groupEnd();
    }
    
    runTests();
  }, []);
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-[#6F263D] to-[#236192]">
      <ErrorBoundary>
        <AppContent />
      </ErrorBoundary>
    </div>
  );
}

export default App;